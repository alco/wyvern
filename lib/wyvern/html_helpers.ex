defmodule Wyvern.View.HTMLHelpers do
  def link_to(target, name) do
    ~s'<a href="#{target}">#{name}</a>'
  end

  def link_to(target, name, attrs) do
    attrstr =
      attrs
      |> Enum.map(fn {k, v} -> ~s'#{k}="#{v}"' end)
      |> Enum.join(" ")
    ~s'<a href="#{target}" #{attrstr}>#{name}</a>'
  end

  def render_tag(thing, tag, opts \\ []) do
    if Enumerable.impl_for(thing) do
      for item <- thing do
        render_single_tag(item, tag, opts)
      end |> Enum.join("\n")
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

  defp render_single_tag({:src, file}, :stylesheet, _) do
    # FIXME: escape quotes in file
    ~s'<link href="#{file}" rel="stylesheet">'
  end
end
