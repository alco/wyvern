defmodule WyvernTest.IndexViewTest do
  import WyvernTest.TestHelpers

  use ExUnit.Case


  defmodule Views do
    base_layout = {:inline, "Base layout (<%= @name %>): <%= yield %>|<%= yield :footer %>"}
    sub_layout = {:inline, "-<%= yield %>-"}
    template = {:inline, "hello world<% content_for :footer do %>a footer<% end %>"}

    #require Wyvern
    #Wyvern.compile_views([
      #[layers:
    #])
  end

  test "multiple views" do
  end


  defmodule IndexView do
    base_layout = {:inline, "Base layout (<%= @name %>): <%= yield %>|<%= yield :footer %>"}
    sub_layout = {:inline, "-<%= yield %>-"}
    template = {:inline, "hello world<% content_for :footer do %>a footer<% end %>"}

    use Wyvern.View, [
      views_root: views_root,
      layers: ["layout", "index"],
    ]
  end

  test "single-module compiled view" do
    attrs = %{
      title: "Test Page",
      stylesheets: [src: "/css/style1.css", src: "/css/style2.css"],
      scripts: [inline: ~s'console.log("hi")', src: "/ui.js"],
      cond: true,
      then: "then",
    }

    result   = IndexView.render(attrs)
    expected = File.read!(Path.join(views_root, "layout_rendered.html"))
    assert result == expected
  end
end
