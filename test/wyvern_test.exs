defmodule WyvernTest.Templates do
  use ExUnit.Case

  import Wyvern.TestHelpers

  test "basic string templates" do
    template = "Hello world!"
    assert Wyvern.render_view({:inline, template})
           == "Hello world!"

    template = "Hello <%= model[:name] %>!"
    assert Wyvern.render_view({:inline, template})
           == "Hello !"
    assert Wyvern.render_view({:inline, template}, model: [name: "people"])
           == "Hello people!"
  end

  test "basic file template" do
    config = [views_root: views_root, model: [name: "people"]]
    assert Wyvern.render_view("basic", config) == "Hello people!\n"
  end

  test "template logic" do
    template = """
    I have these:<%= for i <- model.items do %>
      <%= i %>
    <% end %>
    <%= if model.thing do %>
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

    config = [model: %{items: [1,2,3], thing: false}]

    assert Wyvern.render_view({:inline, template}, config)
           == expected
  end
end

defmodule WyvernTest.Layers do
  use ExUnit.Case

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

  test "layers share the model" do
    layers = [
      {:inline, "all the <%= model[:name] %> <%= yield %>"},
      {:inline, "love some <%= yield %>"},
      {:inline, "<%= model[:name] %>"},
    ]
    assert Wyvern.render_view(layers, model: [name: "people"])
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
