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
    quoted = Wyvern.compile_view(layers, opts)

    q = quote context: nil do
      def render(attrs) do
        unquote(quoted)
      end
    end

    #q |> IO.inspect |> Macro.to_string |> IO.puts

    q
  end
end
