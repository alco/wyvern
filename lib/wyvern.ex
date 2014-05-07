defmodule Wyvern do
  use Application.Behaviour

  def start(_, _) do
    Wyvern.Supervisor.start_link
  end

  @default_config [
    ext: "html",
    engine: :eex,
  ]

  @known_engines [
    {"eex", :eex},
  ]

  @common_imports (quote do
    import Wyvern.View.Helpers, only: [render: 2]
  end)

  @html_imports (quote do
    import Wyvern.View.HTMLHelpers, only: [link_to: 2, link_to: 3]
  end)


  def render_view(layers, config \\ []) do
    result = if config[:autocompile] do
      layers_to_quoted(layers, config, true)
    else
      layers_to_quoted(layers, config, false)
      |> render_quoted(config)
    end

    if file_opts = config[:file_opts] do
      config = Keyword.merge(@default_config, config)
      output_dir = file_opts[:output_dir]
      name = List.last(layers)
      filename = Path.basename(name) <> "." <> file_opts[:ext]
      outpath = Path.join(output_dir, filename)
      write_to_file_if_needed(result, name, outpath, config)
    else
      result
    end
  end


  def define_layout(layers, opts \\ []) do
    key = :erlang.phash2({layers, opts})

    if mod = Wyvern.Cache.get(key) do
      mod
    else
      {quoted, _} = layers_to_quoted(layers, [], false)
      static_attrs = Macro.escape(opts[:attrs]) || []

      module_body = quote context: nil do
        def render(content, fragments, attrs) do
          attrs = unquote(static_attrs) ++ attrs
          unquote(quoted)
        end
      end

      {:module, name, _beam, _} = Module.create(gen_mod_name(), module_body)
      Wyvern.Cache.put(key, name)
      if layout_alias = opts[:name] do
        Wyvern.Cache.put(layout_alias, {:layout, name})
      end
      name
    end
  end

  defmacro layout_to_function(layers, config) do
    layers_to_quoted(layers, config, false)
    |> wrap_in_function(config[:attrs])
  end


  defp wrap_in_function({quoted, false}, attrs) do
    static_attrs = Macro.escape(attrs) || []

    q = quote context: nil do
      def render(content, fragments, attrs) do
        attrs = unquote(static_attrs) ++ attrs
        unquote(quoted)
      end
    end

    #q |> IO.inspect |> Macro.to_string |> IO.puts

    q
  end


  defp write_to_file_if_needed(data, name, path, config) do
    opts = config[:file_opts]
    write? = cond do
      opts[:check] == :timestamp ->
        case File.stat(path) do
          {:ok, stat} ->
            {template_path, _} = template_path_from_name(name, config)
            template_stat = File.stat!(template_path)
            not time_is_newer(stat.mtime, template_stat.mtime)
          {:error, :enoent} -> true
        end

      opts[:check] == :checksum ->
        template_path = template_path_from_name(name, config)
        new_checksum = :erlang.crc32(data)
        old_checksum = Wyvern.Cache.get({:checksum, template_path})
        Wyvern.Cache.put({:checksum, template_path}, new_checksum)
        if old_checksum do
          old_checksum != new_checksum
        else
          true
        end

      true -> true
    end

    if write? do
      IO.puts "[wyvern] Writing template #{name}"
      File.write!(path, data)
    end
  end


  defp time_is_newer(t1, t2) do
    seconds1 = :calendar.datetime_to_gregorian_seconds(t1)
    seconds2 = :calendar.datetime_to_gregorian_seconds(t2)
    seconds1 > seconds2
  end

  def render_views(views, config) do
    file_opts = config[:file_opts]
    cache_path = Path.join(file_opts[:output_dir], ".view_checksums")

    # prepare cache
    if file_opts[:check] == :checksum do
      case File.read(cache_path) do
        {:ok, data} ->
          map = :erlang.binary_to_term(data)
          Wyvern.Cache.reset(map)

        _ -> nil
      end
    end

    Enum.each(views, fn layers ->
      render_view(layers, config)
    end)

    # save cache
    if file_opts[:check] == :checksum do
      map = Wyvern.Cache.get_state()
      File.write!(cache_path, :erlang.term_to_binary(map))
    end
  end


  def compile_layers(layers, config \\ []) do
    layers_to_quoted(layers, config, false)
  end


  defp layers_to_quoted(layers, config, render?) do
    layers = List.wrap(layers)
    if layers == [] do
      raise ArgumentError, message: "At least one layer required to build a view or layout"
    end

    config = Keyword.merge(@default_config, config)

    pid = self()
    #spawn(fn ->
      #try do
        Enum.each(layers, fn view ->
          s = preprocess_template(view, {pid, config})
          # we have to use send() here because preprocess_template also sends
          send(pid, {:stage, s, view})
        end)
      #rescue
        #e -> send(pid, {:exception, IO.inspect(e)})
      #end
      send(pid, :finished)
    #end)

    {stages, leaf_has_yield} =
      collect_fragment_messages([], [], false)
      |> validate_stages()

    # stages are reversed from the original order of layers at this point
    if render? do
      modules =
        [build_compiled_template(hd(stages), config)
         | Enum.map(tl(stages), &build_compiled_template(&1, config))]

      render_modules(modules, config)
    else
      # Old way of template compilation to keep the tests passing for now
      quoted =
        stages
        |> Enum.map(fn
          {stage, _view, fragments} -> {stage, fragments}
          {:layout, _}=stage -> stage
        end)
        |> build_template(leaf_has_yield)
        |> wrap_quoted(config)
      {quoted, not leaf_has_yield}
    end
  end


  defp validate_stages([{stage, view, fragments, has_yield} | rest]) do
    filtered_stages = [{stage, view, fragments} | validate_rest_stages(rest)]
    {filtered_stages, has_yield}
  end

  defp validate_rest_stages([]), do: []

  defp validate_rest_stages([{{:layout, _}=stage, _, _, _} | rest]) do
    [stage | validate_rest_stages(rest)]
  end

  defp validate_rest_stages([{_, _, _, false}|_]) do
    raise ArgumentError, message: "Only one leaf layer allowed"
  end

  defp validate_rest_stages([{stage, view, fragments, _} | rest]) do
    [{stage, view, fragments} | validate_rest_stages(rest)]
  end


  defp render_modules(modules, config) do
    render_modules_with_content(modules, nil, [], config[:attrs])
  end

  defp render_modules_with_content([], content, _, _) do
    content
  end

  defp render_modules_with_content([m|rest], content, fragments, attrs) do
    {new_content, m_fragments} = m.render(content, fragments, attrs)
    new_fragments = merge_compiled_fragments(fragments, m_fragments)
    render_modules_with_content(rest, new_content, new_fragments, attrs)
  end


  defp merge_compiled_fragments(fragments, new_fragments) do
    Keyword.merge(new_fragments, fragments, fn(_, f1, f2) ->
      f1 <> f2
    end)
  end


  defp wrap_quoted(quoted, config) do
    imports = case config[:imports] do
      nil -> nil
      list -> Enum.map(list, fn mod -> quote do: import unquote(mod) end)
    end
    quote do
      unquote(@common_imports)
      unquote(if config[:ext] == "html", do: @html_imports)
      unquote(imports)
      unquote(quoted)
    end
  end


  defp render_quoted({quoted, is_leaf}, config) do
    bindings = if is_leaf do
      [attrs: config[:attrs]]
    else
      [content: nil, fragments: [], attrs: config[:attrs]]
    end
    {result, _} = Code.eval_quoted(quoted, bindings)
    result
  end


  defp collect_fragment_messages(fragments, stages, has_yield) do
    receive do
      {:fragment, f} ->
        new_fragments = Wyvern.View.Helpers.merge_fragments(fragments, f)
        collect_fragment_messages(new_fragments, stages, has_yield)

      :yield ->
        collect_fragment_messages(fragments, stages, true)

      {:stage, s, v} ->
        collect_fragment_messages([], [{s, v, fragments, has_yield}|stages], false)

      :finished ->
        if fragments != [] do
          raise RuntimeError, message: "Inconsistent message flow"
        end
        stages

      {:exception, e} -> raise e
    end
  end


  defp preprocess_template({:inline, view}, {pid, config}) do
    config = Keyword.put(config, :current_template_dir, nil)
    SEEx.compile_string(view, {pid, config}, [engine: Wyvern.SuperSmartEngine])
  end

  defp preprocess_template(modname, _) when is_atom(modname) do
    if Keyword.get_values(modname.__info__(:functions), :render) != [3] do
      raise ArgumentError, message: "Expected a layout module in layers"
    end
    {:layout, modname}
  end

  defp preprocess_template(name, {pid, config}) when is_binary(name) do
    if mod = Wyvern.Cache.get(name) do
      mod
    else
      {path, config} = template_path_from_name(name, config)
      config = Keyword.put(config, :current_template_dir, Path.dirname(path))
      SEEx.compile_file(path, {pid, config}, [engine: Wyvern.SuperSmartEngine])
    end
  end


  defp template_path_from_name(name, config) do
    {filename, config} = make_filename(name, config)
    base_path = get_templates_dir(config)
    {Path.join(base_path, filename), config}
  end

  defp build_compiled_template({stage, view, fragments}, config) do
    if cached = Wyvern.Cache.get(view) do
      #IO.puts "Got from cache: #{inspect cached}"
      cached
    else
      quoted = build_template_dynamic([{stage, fragments}]) |> wrap_quoted(config)

      module_body = quote context: nil do
        def render(content, fragments, attrs) do
          {unquote(quoted), unquote(fragments)}
        end
      end
      {:module, name, _beam, _} = Module.create(gen_mod_name(), module_body)
      Wyvern.Cache.put(view, name)
      name
    end
  end

  defp build_compiled_template({:layout, modname}, _config) do
    modname
  end

  defp gen_mod_name() do
    {mega, sec, micro} = :os.timestamp()
    t = "#{mega}#{sec}#{micro}"
    Module.concat(Wyvern.GeneratedView, t)
  end

  defp build_template(stages, true) do
    # Leaf layer has a yield placeholder. This means that it'll be compiled
    # into a layout and it should accept its content and any additional
    # fragments as function arguments at run time
    build_template_dynamic(stages)
  end

  defp build_template(stages, false) do
    # Leaf layer will be used as a view, so we can compile all the content and
    # fragments right into the resulting AST.
    build_template_static(stages)
  end


  defp build_template_dynamic([{quoted, fragments}|rest]) do
    # First stage is special because we know it will take its content and fragments
    # as function arguments
    content = replace_fragments_dynamic(quoted)
    build_template_dynamic(rest, fragments, content)
  end

  defp build_template_dynamic([], _fragments, content) do
    content
  end

  defp build_template_dynamic([{:layout, modname}|rest], fragments, content) do
    quoted = quote context: nil do
      unquote(modname).render(unquote(content), unquote(fragments), attrs)
    end
    build_template_dynamic(rest, fragments, quoted)
  end

  defp build_template_dynamic([{quoted, stage_frags}|rest], fragments, content) do
    # we use replace_fragments_static here to merge all layers into one,
    # but we still need to accept additional fragments as arguments
    quoted = replace_fragments_static(quoted, fragments, content, true)
    new_fragments = Wyvern.View.Helpers.merge_fragments(stage_frags, fragments)
    build_template_dynamic(rest, new_fragments, quoted)
  end


  defp replace_fragments_dynamic({f, meta, args}) when is_list(args) do
    {replace_fragments_dynamic(f),
     meta,
     replace_fragments_dynamic(args)}
  end

  defp replace_fragments_dynamic(list) when is_list(list) do
    Enum.map(list, &replace_fragments_dynamic/1)
  end

  # FIXME: 2-tuple is also a valid quoted form, so we need to distinguish
  # <% yield :name %> from [yield: :name]

  defp replace_fragments_dynamic({{:yield, nil}}) do
    quote [context: nil], do: content
  end

  defp replace_fragments_dynamic({{:yield, section}}) do
    quote [context: nil], do: fragments[unquote(section)]
  end

  defp replace_fragments_dynamic({a, b}) do
    {replace_fragments_dynamic(a), replace_fragments_dynamic(b)}
  end

  defp replace_fragments_dynamic(other), do: other


  defp build_template_static(stages) do
    build_template_static(stages, [], nil)
  end

  defp build_template_static([], _fragments, content) do
    content
  end

  defp build_template_static([{:layout, modname}|rest], fragments, content) do
    quoted = quote context: nil do
      unquote(modname).render(unquote(content), unquote(fragments), attrs)
    end
    build_template_static(rest, fragments, quoted)
  end

  defp build_template_static([{quoted, stage_frags}|rest], fragments, content) do
    quoted = replace_fragments_static(quoted, fragments, content)
    new_fragments = Wyvern.View.Helpers.merge_fragments(stage_frags, fragments)
    build_template_static(rest, new_fragments, quoted)
  end


  defp replace_fragments_static(quoted, fragments, content), do:
    replace_fragments_static(quoted, fragments, content, false)

  defp replace_fragments_static({f, meta, args}, fragments, content, non_leaf?) when is_list(args) do
    {replace_fragments_static(f, fragments, content, non_leaf?),
     meta,
     replace_fragments_static(args, fragments, content, non_leaf?)}
  end

  defp replace_fragments_static(list, fragments, content, non_leaf?) when is_list(list) do
    Enum.map(list, &replace_fragments_static(&1, fragments, content, non_leaf?))
  end

  # FIXME: 2-tuple is also a valid quoted form, so we need to distinguish
  # <% yield :name %> from [yield: :name]

  defp replace_fragments_static({{:yield, nil}}, _fragments, content, _non_leaf?) do
    content
  end

  defp replace_fragments_static({{:yield, section}}, fragments, _content, non_leaf?) do
    if non_leaf? do
      quote [context: nil] do
        unquote(fragments[section] || "") <> (fragments[unquote(section)] || "")
      end
    else
      fragments[section]
    end
  end

  defp replace_fragments_static({a, b}, fragments, content, non_leaf?) do
    {replace_fragments_static(a, fragments, content, non_leaf?),
     replace_fragments_static(b, fragments, content, non_leaf?)}
  end

  defp replace_fragments_static(other, _, _, _) do
    other
  end


  def render_partial(name, {_pid, config}=state) do
    config = Keyword.merge(@default_config, config || [])
    {filename, _config} = make_filename(name, config, partial: true)
    base_path = if String.contains?(name, "/") do
      get_partials_dir(config)
    else
      config[:current_template_dir]
    end
    if base_path == nil do
      raise ArgumentError, message: "Can only use shared partials in dynamic views"
    end
    path = Path.join(base_path, filename)

    SEEx.compile_file(path, state, [engine: Wyvern.SuperSmartEngine])
  end


  defp make_filename(name, config, opts \\ []) do
    filename = if String.contains?(name, ".") do
      config = detect_engine(name, config)
      name
    else
      name <> make_ext(config)
    end

    if opts[:partial] do
      filename = Path.join(Path.dirname(filename), "_" <> Path.basename(filename))
    end

    {filename, config}
  end

  defp detect_engine(name, config) do
    [_, ext] = Regex.run(~r/\.([^.]+)$/, name)
    case List.keyfind(@known_engines, ext, 0) do
      {_, engine} -> Keyword.put(config, :engine, engine)
      nil         -> config  # will use the default engine
    end
  end

  defp make_ext(config) do
    ext = config[:ext]
    engine_ext = map_engine(config[:engine])
    ".#{ext}.#{engine_ext}"
  end

  defp map_engine(:eex), do: "eex"

  defp get_views_root(config), do:
    config[:views_root] || "lib/#{Mix.Project.config[:app]}/views"

  defp get_templates_dir(config) do
    if path = config[:templates_dir] do
      path
    else
      Path.join(get_views_root(config), "templates")
    end
  end

  defp get_partials_dir(config) do
    if path = config[:partials_dir] do
      path
    else
      Path.join(get_views_root(config), "partials")
    end
  end
end
