defmodule WyvernTest.Templates do
  use ExUnit.Case

  import Wyvern.TestHelpers

  test "basic string templates" do
    template = "Hello world!"
    assert Wyvern.render_view([], layers: [{:inline, template}])
           == "Hello world!"

    template = "Hello <%= model[:name] %>!"
    assert Wyvern.render_view([], layers: [{:inline, template}])
           == "Hello !"
    assert Wyvern.render_view([name: "people"], layers: [{:inline, template}])
           == "Hello people!"
  end

  test "basic file template" do
    assert Wyvern.render_view([name: "people"], [layers: ["basic"]], [views_root: views_root])
           == "Hello people!\n"
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
    assert Wyvern.render_view([], [layers: layers]) == "1 2 3"

    layers = [
      {:inline, "1 <%= yield %>"},
      {:inline, "2 <%= yield %>"},
      {:inline, "3 <%= yield %>"},
    ]
    assert Wyvern.render_view([], [layers: layers]) == "1 2 3 "
  end

  test "layers share the model" do
    layers = [
      {:inline, "all the <%= model[:name] %> <%= yield %>"},
      {:inline, "love some <%= yield %>"},
      {:inline, "<%= model[:name] %>"},
    ]
    assert Wyvern.render_view([name: "people"], [layers: layers])
           == "all the people love some people"
  end

  test "disjointed content" do
    layers = [
      {:inline, "top level <%= yield %>"},
      {:inline, "middle level"},
      {:inline, "bottom level"},
    ]
    assert Wyvern.render_view([], [layers: layers])
           == "top level middle level"
  end
end
