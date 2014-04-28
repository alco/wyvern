defmodule Wyvern do
  @partials_root "lib/:app/views/partials"
  @templates_root "lib/:app/views/templates"

  @default_config [
    views_root: "lib/:app/views",
    ext: "html.eex",
  ]


  def render_string(str, opts) do
    model = opts[:model]

    q = quote context: nil do
      import Wyvern.View, only: [link_to: 3, render: 1, render: 2, content_for: 2]
      unquote(EEx.compile_string(str, [engine: Wyvern.SuperSmartEngine]))
    end
    {result, _} = Code.eval_quoted(q, [model: model])
    result
  end

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

  defp render_template({:inline, view}, context, _config) do
    q = quote context: nil do
      import Wyvern.View, only: [link_to: 3, render: 1, render: 2, content_for: 2]
      unquote(EEx.compile_string(view, [engine: Wyvern.SuperSmartEngine]))
    end
    {result, _} = Code.eval_quoted(q, [model: context[:model]])
    Keyword.put(context, :content, result)
  end

  defp render_template(name, context, config) do
    filename = Enum.join([name, config[:ext]], ".")

    path = Path.join(config[:views_root], filename)

    #path = if String.contains?(name, "/") do
      #Path.join(@views_root, filename)
    #else
      #Path.join(@templates_root, filename)
    #end

    q = quote context: nil do
      import Wyvern.View, only: [link_to: 3, render: 1, render: 2, content_for: 2]
      unquote(EEx.compile_file(path, [engine: Wyvern.SuperSmartEngine]))
    end
    {result, _} = Code.eval_quoted(q, [model: context[:model]], file: filename)
    Keyword.put(context, :content, result)
  end

  def render_partial(name, config) do
    filename = Enum.join(["_"<>name, config[:ext]], ".")
    path = Path.join(@partials_root, filename)

    q = quote context: nil do
      import Wyvern.View, only: [link_to: 3, render: 1, render: 2, content_for: 2]
      unquote(EEx.compile_file(path, [engine: Wyvern.SuperSmartEngine]))
    end
    {result, _} = Code.eval_quoted(q, [], file: filename)
    result
  end
end
