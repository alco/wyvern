defmodule WyvernTest.Templates do
  use ExUnit.Case

  import Wyvern.TestHelpers

  test "basic string templates" do
    template = "Hello world!"
    assert Wyvern.render_view({:inline, template})
           == "Hello world!"

    template = "Hello <%= @name %>!"
    assert Wyvern.render_view({:inline, template})
           == "Hello !"
    assert Wyvern.render_view({:inline, template}, attrs: [name: "people"])
           == "Hello people!"

    template = "Hello <%= @model[:name] %>!"
    assert Wyvern.render_view({:inline, template})
           == "Hello !"
    assert Wyvern.render_view({:inline, template}, attrs: [model: [name: "people"]])
           == "Hello people!"
  end

  test "basic file template" do
    config = [views_root: views_root, attrs: [name: "people"]]
    assert Wyvern.render_view("basic", config) == "Hello people!\n"
  end

  test "template logic" do
    template = """
    I have these:<%= for i <- @model.items do %>
      <%= i %>
    <% end %>
    <%= if @model.thing do %>
      Hello.<% x = 1 %>
    <% else %>
      Bye.<% x = 2 %>
    <% end %>
    Also see "<%= x %>".
    """

    expected = """
    I have these:
      1

      2

      3


      Bye.

    Also see "2".
    """

    config = [attrs: [model: %{items: [1,2,3], thing: false}]]

    result = Wyvern.render_view({:inline, template}, config)
    assert result == expected
  end
end

defmodule WyvernTest.Layers do
  use ExUnit.Case

  test "empty layers" do
    assert_raise ArgumentError, fn ->
      Wyvern.render_view([])
    end
  end

  test "simple layering" do
    layers = [
      {:inline, "1 <%= yield %>"},
      {:inline, "2 <%= yield %>"},
      {:inline, "3"},
    ]
    assert Wyvern.render_view(layers) == "1 2 3"

    layers = [
      {:inline, "1 <%= yield %>"},
      {:inline, "2 <%= yield %>"},
      {:inline, "3 <%= yield %>"},
    ]
    assert Wyvern.render_view(layers) == "1 2 3 "
  end

  test "layers share the attrs" do
    layers = [
      {:inline, "all the <%= @name %> <%= yield %>"},
      {:inline, "love some <%= yield %>"},
      {:inline, "<%= @name %>"},
    ]
    assert Wyvern.render_view(layers, attrs: [name: "people"])
           == "all the people love some people"
  end

  test "disjointed content" do
    layers = [
      {:inline, "top level <%= yield %>"},
      {:inline, "middle level"},
      {:inline, "bottom level"},
    ]
    assert Wyvern.render_view(layers)
           == "top level middle level"
  end
end
