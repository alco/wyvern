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
    import Wyvern.View.Helpers, only: [render: 1, render: 2]
  end)

  @html_imports (quote do
    import Wyvern.View.HTMLHelpers, only: [link_to: 2, link_to: 3]
  end)


  def render_view(model, opts, config \\ []) do
    layers = opts[:layers]
    config = Keyword.merge(@default_config, config)
    context =
      layers
      |> Enum.reverse()
      |> Enum.reduce([content: nil, model: model], fn view, context ->
        render_template(view, context, config)
      end)
    context[:content]
  end

  defp render_template({:inline, view}, context, config) do
    q = quote context: nil do
      unquote(@common_imports)
      unquote(if config[:ext] == "html", do: @html_imports)
      unquote(EEx.compile_string(view, [engine: Wyvern.SuperSmartEngine]))
    end
    {result, _} = Code.eval_quoted(q, [model: context[:model], _context: context])
    Keyword.put(context, :content, result)
  end

  defp render_template(name, context, config) do
    {filename, config} = make_filename(name, config)
    path = Path.join(config[:views_root], filename)

    #path = if String.contains?(name, "/") do
      #Path.join(@views_root, filename)
    #else
      #Path.join(@templates_root, filename)
    #end

    q = quote context: nil do
      unquote(@common_imports)
      unquote(if config[:ext] == "html", do: @html_imports)
      unquote(EEx.compile_file(path, [engine: Wyvern.SuperSmartEngine]))
    end
    {result, _} = Code.eval_quoted(q, [model: context[:model], _context: context], file: filename)
    Keyword.put(context, :content, result)
  end


  def render_partial(name, config) do
    config = Keyword.merge(@default_config, config || [])
    {filename, _config} = make_filename(name, config, partial: true)
    path = Path.join(config[:partials_root], filename)

    q = quote context: nil do
      unquote(@common_imports)
      unquote(if config[:ext] == "html", do: @html_imports)
      unquote(EEx.compile_file(path, [engine: Wyvern.SuperSmartEngine]))
    end
    {result, _} = Code.eval_quoted(q, [], file: filename)
    result
  end

  def render_tag(thing, tag, opts) do
    if Enumerable.impl_for(thing) do
      for item <- thing do
        render_single_tag(item, tag, opts)
      end
    else
      render_single_tag(thing, tag, opts)
    end
  end

  defp render_single_tag({:src, file}, :script, _) do
    # FIXME: escape quotes in file
    ~s'<script src="#{file}" type="application/javascript"></script>'
  end

  defp render_single_tag({:inline, text}, :script, _) do
    # FIXME: escape html in text
    ~s'<script type="application/javascript">#{text}</script>'
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
