defmodule WyvernTest.ViewTest do
  use ExUnit.Case


  defmodule Views do
    # FIXME: support for variables as arguments
    #base_layout = {:inline, "Base layout (<%= @name %>): <%= yield %>|<%= yield :footer %>"}
    #sub_layout = {:inline, "-<%= yield %>-"}
    #template = {:inline, "hello world<% content_for :footer do %>a footer<% end %>"}

    #predef_layout = Wyvern.define_layout([sub_layout])

    require Wyvern
    Wyvern.compile_views([
      [layers: [
        {:inline, "Base layout (<%= @name %>): <%= yield %>|<%= yield :footer %>"},
        {:inline, "hello world<% content_for :footer do %>a footer<% end %>"},
      ], name: "basic_view"],

      [layers: [
        {:inline, "Base layout (<%= @name %>): <%= yield %>|<%= yield :footer %>"},
        {:inline, "-<%= yield %>-"},
        {:inline, "hello world<% content_for :footer do %>a footer<% end %>"}
      ], name: "nested_view"],
    ])
  end

  test "multiple views" do
    expected = "Base layout (): hello world|a footer"
    assert Views.render("basic_view") == expected

    expected = "Base layout (name): -hello world-|a footer"
    assert Views.render("nested_view", name: "name") == expected
  end


  defmodule SingleView do
    base_layout = {:inline, "Base layout (<%= @name %>): <%= yield %>|<%= yield :footer %>"}
    sub_layout = {:inline, "-<%= yield %>-"}
    template = {:inline, "hello world<% content_for :footer do %>a footer<% end %>"}

    use Wyvern.View, [
      layers: [base_layout, sub_layout, template],
    ]
  end

  test "single-module compiled view" do
    expected = "Base layout (Name): -hello world-|a footer"
    assert SingleView.render(name: "Name") == expected
  end
end
