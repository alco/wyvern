defmodule WyvernTest.DefineLayoutTest do
  use ExUnit.Case

  test "anonymous layout" do
    layers = [
      {:inline, "Base layout\n<%= yield %>\n<%= yield :footer %>\n"},
      {:inline, "---\n<%= yield %>\n---"},
    ]
    layout = Wyvern.define_layout(layers)

    template = "hi<% content_for :footer do %>this is a footer<% end %>"
    expected = """
    Base layout
    ---
    hi
    ---
    this is a footer
    """

    assert Wyvern.render_view([layout, {:inline, template}]) == expected
  end

  test "named layout" do
    layers = [
      {:inline, "Named layout\n<%= yield %>\n<%= yield :footer %>\n"},
      {:inline, "---\n<%= yield %>\n---"},
    ]
    layout = Wyvern.define_layout(layers, name: "layout:named")

    template = "hi<% content_for :footer do %>this is a footer<% end %>"
    expected = """
    Named layout
    ---
    hi
    ---
    this is a footer
    """

    assert Wyvern.render_view(["layout:named", {:inline, template}]) == expected
  end
end
