defmodule WyvernTest.CompiledLayoutTest do
  use ExUnit.Case

  defmodule Layouts do
    require Wyvern
    # FIXME: should be able to pass variables into the compile_layouts call
    Wyvern.compile_layouts([
      [layers: [
        {:inline, "top -><%= yield %><- content || <%= yield :footer %>"},
        {:inline, "--<%= yield %>--"},
      ], name: "layout:compiled"],
    ])
  end

  test "layout function" do
    template = "This is a view.<% content_for :footer do %>This is a footer.<% end %>"
    layers = [
      Layouts.layout("layout:compiled"),
      {:inline, template},
    ]
    expected = "top ->--This is a view.--<- content || This is a footer."
    assert Wyvern.render_view(layers) == expected
  end
end
