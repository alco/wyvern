defmodule WyvernTest.LayeredLayout do
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
    assert BaseLayout.__info__(:functions) == [render: 3]
    assert NavbarLayout.__info__(:functions) == [render: 3]

    assert BaseLayout.render(nil, [], []) == "->  <-"
    assert BaseLayout.render("content", [], []) == "-> content <-"

    assert NavbarLayout.render(nil, [], []) == "...."
    assert NavbarLayout.render("content", [], []) == "...content."

    result = NavbarLayout.render("content", [head: "hi"], [])
    assert result == "hi...content."
  end


  defmodule IndexViewStatic do
    use Wyvern.View, [
      layers: [
        BaseLayout,
        NavbarLayout,
        {:inline, "hi<% content_for :head do %>HEAD<% end %>"},
      ]
    ]
  end

  test "static layout" do
    assert IndexViewStatic.__info__(:functions) == [render: 1]
    assert IndexViewStatic.render([]) == "-> HEAD...hi. <-"
  end


  defmodule CombinedLayout do
    use Wyvern.Layout, [
      layers: [
        {:inline, "-> <%= yield %> <-"},
        {:inline, "<%= yield :head %>...<%= yield %>."},
      ]
    ]
  end

  test "combined layout" do
    assert CombinedLayout.render(nil, [], []) == "-> .... <-"
    assert CombinedLayout.render("content", [], []) == "-> ...content. <-"

    result = CombinedLayout.render("content", [head: "hi"], [])
    assert result == "-> hi...content. <-"
  end


  test "compiled layout" do
    layers = [
      {:inline, "<%= @title %>: -> <%= yield %> <-"},
      {:inline, "<%= yield :head %>...<%= yield %>."},
    ]
    layout = Wyvern.compile_layout(layers, attrs: [title: "hello"])

    template = "<% content_for :head do %>hi<% end %>I am a view"
    expected = "hello: -> hi...I am a view. <-"

    assert Wyvern.render_view([layout, {:inline, template}]) == expected
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
    assert MixedLayout.render(nil, [], []) == "-> .... <-"
    assert MixedLayout.render("content", [], []) == "-> ...content. <-"
    assert MixedLayout.render("content", [head: "HEAD"], []) == "-> HEAD...content. <-"
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
end
