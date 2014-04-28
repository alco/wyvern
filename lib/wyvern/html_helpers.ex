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
end
