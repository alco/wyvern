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
    quoted = template_to_quoted(layers, config)
    render_quoted(quoted, config)
  end


  def compile_view(layers, config \\ []) do
    template_to_quoted(layers, config)
  end


  defp template_to_quoted(layers, config) do
    layers = List.wrap(layers)
    config = Keyword.merge(@default_config, config)

    pid = self()
    spawn(fn ->
      try do
        Enum.each(layers, fn view ->
          s = preprocess_template(view, {pid, config})
          send(pid, {:stage, s})
        end)
      rescue
        e -> send(pid, {:exception, e})
      end
      send(pid, :finished)
    end)

    stages = collect_fragment_messages([], [])

    quoted = build_template(stages, [], nil)
    wrap_quoted(quoted, config)
  end


  defp wrap_quoted(quoted, config) do
    quote do
      unquote(@common_imports)
      unquote(if config[:ext] == "html", do: @html_imports)
      unquote(quoted)
    end
  end


  defp render_quoted(quoted, config) do
    {result, _} = Code.eval_quoted(quoted, [model: config[:model]])
    result
  end


  defp collect_fragment_messages(fragments, stages) do
    receive do
      {:fragment, f} ->
        new_fragments = Wyvern.View.Helpers.merge_fragments(fragments, f)
        collect_fragment_messages(new_fragments, stages)

      {:stage, s} ->
        collect_fragment_messages([], [{s, fragments}|stages])

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

  defp preprocess_template(name, {_pid, config}=state) do
    {filename, config} = make_filename(name, config)
    base_path = if String.contains?(name, "/") do
      get_views_root(config)
    else
      get_templates_root(config)
    end
    path = Path.join(base_path, filename)
    SEEx.compile_file(path, state, [engine: Wyvern.SuperSmartEngine])
  end


  defp build_template([], _fragments, content) do
    content
  end

  defp build_template([{quoted, stage_frags}|rest], fragments, content) do
    quoted = replace_fragments(quoted, fragments, content)
    new_fragments = Wyvern.View.Helpers.merge_fragments(stage_frags, fragments)
    build_template(rest, new_fragments, quoted)
  end


  defp replace_fragments({f, meta, args}, fragments, content) when is_list(args) do
    {f, meta, Enum.map(args, &replace_fragments(&1, fragments, content))}
  end

  defp replace_fragments({:yield, nil}, _fragments, content) do
    content
  end

  defp replace_fragments({:yield, section}, fragments, _content) do
    fragments[section]
  end

  defp replace_fragments(other, _, _) do
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
