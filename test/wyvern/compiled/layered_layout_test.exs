defmodule WyvernTest.LayeredLayoutTest do
  use ExUnit.Case

  defmodule IndexViewDynamic do
    use Wyvern.View, [
      layers: [
        {:inline, "-> <%= yield %> <-"},
        {:inline, "<%= yield :head %>...<%= yield %>."},
        {:inline, "hi<% content_for :head do %>HEAD<% end %>"},
      ]
    ]
  end

  test "dynamic layers" do
    assert IndexViewDynamic.__info__(:functions) == [render: 1]
    assert IndexViewDynamic.render([]) == "-> HEAD...hi. <-"
  end


  defmodule BaseLayout do
    use Wyvern.Layout, [
      layers: [{:inline, "-> <%= yield %> <-"}]
    ]
  end

  defmodule NavbarLayout do
    use Wyvern.Layout, [
      layers: [{:inline, "<%= yield :head %>...<%= yield %>."}]
    ]
  end

  test "layout rendering" do
    assert Keyword.get_values(BaseLayout.__info__(:functions), :_render) == [3]
    assert Keyword.get_values(NavbarLayout.__info__(:functions), :_render) == [3]

    assert BaseLayout._render(nil, [], []) == "->  <-"
    assert BaseLayout._render("content", [], []) == "-> content <-"

    assert NavbarLayout._render(nil, [], []) == "...."
    assert NavbarLayout._render("content", [], []) == "...content."

    result = NavbarLayout._render("content", [head: "hi"], [])
    assert result == "hi...content."
  end


  test "static layout" do
    defmodule IndexViewStatic do
      use Wyvern.View, [
        layers: [
          BaseLayout,
          NavbarLayout,
          {:inline, "hi<% content_for :head do %>HEAD<% end %>"},
        ]
      ]
    end

    assert IndexViewStatic.__info__(:functions) == [render: 1]
    assert IndexViewStatic.render([]) == "-> HEAD...hi. <-"
  end


  test "combined layout" do
    defmodule CombinedLayout do
      use Wyvern.Layout, [
        layers: [
          {:inline, "-> <%= yield %> <-"},
          {:inline, "<%= yield :head %>...<%= yield %>."},
        ]
      ]
    end

    assert CombinedLayout._render(nil, [], []) == "-> .... <-"
    assert CombinedLayout._render("content", [], []) == "-> ...content. <-"

    result = CombinedLayout._render("content", [head: "hi"], [])
    assert result == "-> hi...content. <-"
  end


  test "compiled layout" do
    defmodule CompiledLayout do
      require Wyvern
      Wyvern.layout_to_function([
        {:inline, "<%= @title %>: -> <%= yield %> <-"},
        {:inline, "<%= yield :head %>...<%= yield %>."},
      ], attrs: [title: "hello"])
    end

    template = "<% content_for :head do %>hi<% end %>I am a view"
    expected = "hello: -> hi...I am a view. <-"

    assert Wyvern.render_view([CompiledLayout, {:inline, template}]) == expected
  end


  defmodule MixedLayout do
    use Wyvern.Layout, [
      layers: [
        BaseLayout,
        {:inline, "<%= yield :head %>...<%= yield %>."},
      ]
    ]
  end

  test "mixed layout" do
    assert MixedLayout._render(nil, [], []) == "-> .... <-"
    assert MixedLayout._render("content", [], []) == "-> ...content. <-"
    assert MixedLayout._render("content", [head: "HEAD"], []) == "-> HEAD...content. <-"
  end


  defmodule MixedView do
    use Wyvern.View, [
      layers: [
        MixedLayout,
        {:inline, "some<%= yield %>more<%= yield :more%>content"},
        {:inline, "###<% content_for :head do %>HHH<% end %> <% content_for :more do %>!!!<% end %>@@@"},
      ]
    ]
  end

  test "mixed static dynamic layout" do
    assert MixedView.render([]) == "-> HHH...some### @@@more!!!content. <-"
  end


  # tests the bug where 'yield :more' would not get any content from the leaf
  # layer if there were more layers in-between
  defmodule TransitiveLayout do
    use Wyvern.Layout, [
      layers: [
        {:inline, "<%= yield :more %><%= yield %>"},
        {:inline, "-<%= yield %>-"},
      ]
    ]
  end

  test "transitive fragments layout" do
    template = "hello<% content_for :more do %>[more content]<% end %>"
    expected = "[more content]-hello-"
    assert Wyvern.render_view([TransitiveLayout, {:inline, template}]) == expected
  end
end
