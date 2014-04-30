defmodule Wyvern.View do
  defmacro __using__(opts) do
    layers = opts[:layers]
    quoted = Wyvern.compile_view(layers, opts)

    quote context: nil do
      def render(model) do
        unquote(quoted)
      end
    end
  end
end
