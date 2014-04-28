defmodule WyvernTest do
  use ExUnit.Case

  test "basic string templates" do
    template = "Hello world!"
    assert Wyvern.render_view([], layers: [{:inline, template}])
           == "Hello world!"

    template = "Hello <%= model[:name] %>!"
    assert Wyvern.render_view([], layers: [{:inline, template}])
           == "Hello !"

    template = "Hello <%= model[:name] %>!"
    assert Wyvern.render_view([name: "people"], layers: [{:inline, template}])
           == "Hello people!"
  end

  test "basic file templates" do
    views_root = Path.join([System.cwd(), "test", "fixtures"])
    assert Wyvern.render_view([name: "people"], [layers: ["basic"]], [views_root: views_root])
           == "Hello people!\n"
  end

  test "HTML helpers" do
  end
end
