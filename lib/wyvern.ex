defmodule Wyvern do
  @templates_root "lib/:app/views/templates"

  @default_config [
    partials_root: "lib/:app/views/partials",
    views_root: "lib/:app/views",
    ext: "html",
    engine: :eex,
  ]

  @known_engines [
    {"eex", :eex},
  ]

  @common_imports (quote do
    import Wyvern.View.Helpers, only: [render: 1, render: 2, content_for: 2]
  end)

  @html_imports (quote do
    import Wyvern.View.HTMLHelpers, only: [link_to: 2, link_to: 3]
  end)


  def render_view(model, opts, config \\ []) do
    layers = opts[:layers]
    config = Keyword.merge(@default_config, config)

    stages =
      layers
      |> Enum.reduce([], fn view, stages ->
        s = preprocess_template(view, config)
        [s|stages]
      end)

    render_template(stages, model, [], config, nil)
  end

  defp preprocess_template({:inline, view}, _config) do
    EEx.compile_string(view, [engine: Wyvern.SuperSmartEngine])
  end

  defp preprocess_template(name, config) do
    {filename, config} = make_filename(name, config)
    path = Path.join(config[:views_root], filename)
    EEx.compile_file(path, [engine: Wyvern.SuperSmartEngine])
  end

  defp render_template([], _model, _fragments, _config, content) do
    content
  end

  defp render_template([{quoted, stage_frags}|rest], model, fragments, config, content) do
    quoted = replace_fragments(quoted, fragments)
    q = quote context: nil do
      unquote(@common_imports)
      unquote(if config[:ext] == "html", do: @html_imports)
      unquote(quoted)
    end
    {result, _} = Code.eval_quoted(q, [model: model, _content: content])
    new_fragments = Wyvern.View.Helpers.merge_fragments(stage_frags, fragments)
    render_template(rest, model, new_fragments, config, result)
  end


  defp replace_fragments({f, meta, args}, fragments) when is_list(args) do
    {f, meta, Enum.map(args, &replace_fragments(&1, fragments))}
  end

  defp replace_fragments({:yield, section}, fragments) do
    fragments[section]
  end

  defp replace_fragments(other, _) do
    other
  end


  def render_partial(name, config) do
    config = Keyword.merge(@default_config, config || [])
    {filename, _config} = make_filename(name, config, partial: true)
    path = Path.join(config[:partials_root], filename)

    q = quote context: nil do
      unquote(@common_imports)
      unquote(if config[:ext] == "html", do: @html_imports)
      {result, _} = unquote(EEx.compile_file(path, [engine: Wyvern.SuperSmartEngine]))
      result
    end
    {result, _} = Code.eval_quoted(q, [], file: filename)
    result
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
end
