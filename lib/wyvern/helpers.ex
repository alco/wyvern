defmodule Wyvern.View.Helpers do
  def render([{:partial, name} | opts]) do
    Wyvern.render_partial(name, opts[:config])
  end

  def render(thing, opts) do
    cond do
      tag=opts[:tag] ->
        Wyvern.render_tag(thing, tag, opts[:config])

      true ->
        raise RuntimeError, message: "No other options supported"
    end
  end
end
