defmodule Wyvern do
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
    layers_to_quoted(layers, config)
    |> render_quoted(config)
  end


  def compile_layers(layers, config \\ []) do
    layers_to_quoted(layers, config)
  end


  defp layers_to_quoted(layers, config) do
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
          send(pid, {:stage, s})
        end)
      #rescue
        #e -> send(pid, {:exception, IO.inspect(e)})
      #end
      send(pid, :finished)
    #end)

    {stages, leaf_has_yield} =
      collect_fragment_messages([], [], false)
      |> validate_stages()

    quoted = build_template(stages, leaf_has_yield)
    {wrap_quoted(quoted, config), not leaf_has_yield}
  end


  defp validate_stages([{stage, fragments, has_yield} | rest]) do
    filtered_stages = [{stage, fragments} | validate_rest_stages(rest)]
    {filtered_stages , has_yield}
  end

  defp validate_rest_stages([]), do: []


  defp validate_rest_stages([{{:layout, _}=stage, _, _} | rest]) do
    [stage | validate_rest_stages(rest)]
  end

  defp validate_rest_stages([{_, _, false}|_]) do
    raise ArgumentError, message: "Only one leaf layer allowed"
  end

  defp validate_rest_stages([{stage, fragments, _} | rest]) do
    [{stage, fragments} | validate_rest_stages(rest)]
  end


  defp wrap_quoted(quoted, config) do
    quote do
      unquote(@common_imports)
      unquote(if config[:ext] == "html", do: @html_imports)
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

      {:stage, s} ->
        collect_fragment_messages([], [{s, fragments, has_yield}|stages], false)

      :finished ->
        if fragments != [] do
          raise RuntimeError, message: "Inconsistent message flow"
        end
        stages

      {:exception, e} -> raise e
    end
  end


  defp preprocess_template({:inline, view}, state) do
    SEEx.compile_string(view, state, [engine: Wyvern.SuperSmartEngine])
  end

  defp preprocess_template(modname, _) when is_atom(modname) do
    if Keyword.get_values(modname.__info__(:functions), :render) != [3] do
      raise ArgumentError, message: "Expected a layout module in layers"
    end
    {:layout, modname}
  end

  defp preprocess_template(name, {_pid, config}=state) when is_binary(name) do
    {filename, config} = make_filename(name, config)
    # FIXME: get rid of this. Only the leaf layer is searched in templates/
    # everything else before it is a layout
    base_path = if String.contains?(name, "/") do
      get_views_root(config)
    else
      get_templates_root(config)
    end
    path = Path.join(base_path, filename)
    SEEx.compile_file(path, state, [engine: Wyvern.SuperSmartEngine])
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
    quoted = replace_fragments_static(quoted, fragments, content)
    new_fragments = Wyvern.View.Helpers.merge_fragments(stage_frags, fragments)
    build_template_dynamic(rest, new_fragments, quoted)
  end


  defp replace_fragments_dynamic({:@, _, [{name, _, atom}]})
                                        when is_atom(name) and is_atom(atom) do
    quote [context: nil], do: attrs[unquote(name)]
  end

  defp replace_fragments_dynamic({f, meta, args}) when is_list(args) do
    f = replace_fragments_dynamic(f)
    args = Enum.map(args, &replace_fragments_dynamic/1)
    {f, meta, args}
  end

  # FIXME: 2-tuple is also a valid quoted form, so we need to distinguish
  # <% yield :name %> from [yield: :name]

  defp replace_fragments_dynamic({:yield, nil}) do
    quote [context: nil], do: content
  end

  defp replace_fragments_dynamic({:yield, section}) do
    quote [context: nil], do: fragments[unquote(section)]
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


  defp replace_fragments_static({:@, _, [{name, _, atom}]}, _fragments, _content)
                                        when is_atom(name) and is_atom(atom) do
    quote [context: nil], do: attrs[unquote(name)]
  end

  defp replace_fragments_static({f, meta, args}, fragments, content) when is_list(args) do
    f = replace_fragments_static(f, fragments, content)
    args = Enum.map(args, &replace_fragments_static(&1, fragments, content))
    {f, meta, args}
  end

  # FIXME: 2-tuple is also a valid quoted form, so we need to distinguish
  # <% yield :name %> from [yield: :name]

  defp replace_fragments_static({:yield, nil}, _fragments, content) do
    content
  end

  defp replace_fragments_static({:yield, section}, fragments, _content) do
    fragments[section]
  end

  defp replace_fragments_static(other, _, _) do
    other
  end


  def render_partial(name, {_pid, config}=state) do
    config = Keyword.merge(@default_config, config || [])
    {filename, _config} = make_filename(name, config, partial: true)
    path = Path.join(get_partials_root(config), filename)

    SEEx.compile_file(path, state, [engine: Wyvern.SuperSmartEngine])
  end


  defp make_filename(name, config, opts \\ []) do
    filename = if String.contains?(name, ".") do
      config = detect_engine(name, config)
      name
    else
      name <> make_ext(config)
    end

    if opts[:partial], do: filename = "_" <> filename

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

  defp get_templates_root(config) do
    if path = config[:templates_root] do
      path
    else
      Path.join(get_views_root(config), "templates")
    end
  end

  defp get_partials_root(config) do
    if path = config[:partials_root] do
      path
    else
      Path.join(get_views_root(config), "partials")
    end
  end
end
