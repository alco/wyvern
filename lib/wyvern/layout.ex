defmodule Wyvern.Layout do
  defmacro __using__(opts) do
    quote do
      @wyvern_Layout_Opts unquote(opts)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :wyvern_Layout_Opts)
    layers = opts[:layers]
    Wyvern.compile_layout(layers, opts)
  end
end
