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

  defmacro content_for(section, [do: code]) do
    Process.put({:content, section}, code)
  end

  def merge_fragments(fragments, new_fragments) do
    Keyword.merge(fragments, new_fragments, fn(_, f1, f2) ->
      quote context: nil do
        unquote(f1) <> unquote(f2)
      end
    end)
  end
end
