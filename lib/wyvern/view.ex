defmodule Wyvern.View do
  defmacro __using__(opts) do
    quote do
      @wyvern_View_Opts unquote(opts)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :wyvern_View_Opts)

    layers = opts[:layers]
    {quoted, is_leaf} = Wyvern.compile_layers(layers, opts)

    if not is_leaf do
      raise ArgumentError, message: "A view is not allowed to have 'yield' placeholders"
    end

    static_attrs = Macro.escape(opts[:static_attrs]) || []

    q = quote context: nil do
      def render(attrs) do
        attrs = unquote(static_attrs) ++ attrs
        unquote(quoted)
      end
    end

    #q |> IO.inspect |> Macro.to_string |> IO.puts

    q
  end
end
