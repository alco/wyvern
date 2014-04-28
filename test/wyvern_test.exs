defmodule WyvernTest.Templates do
  use ExUnit.Case

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
    views_root = Path.join([System.cwd(), "test", "fixtures"])
    assert Wyvern.render_view([name: "people"], [layers: ["basic"]], [views_root: views_root])
           == "Hello people!\n"
  end
end

defmodule WyvernTest.HTMLHelpers do
  use ExUnit.Case

  alias Wyvern.View.HTMLHelpers, as: H

  test "link helper" do
    assert H.link_to("/index.html", "Home")
           == ~s'<a href="/index.html">Home</a>'
    assert H.link_to("http://example.com", " example ")
           == ~s'<a href="http://example.com"> example </a>'
    assert H.link_to("#", " example ", class: "active", id: "unique")
           == ~s'<a href="#" class="active" id="unique"> example </a>'
  end

  test "link helper in template" do
    template = ~s'...<%= link_to "/", "Home" %>...'
    assert Wyvern.render_view([], layers: [{:inline, template}])
           == ~s'...<a href="/">Home</a>...'

    template = ~s'...<%= link_to "/", "Home", id: "home" %>...'
    assert Wyvern.render_view([], layers: [{:inline, template}])
           == ~s'...<a href="/" id="home">Home</a>...'
  end

  test "link in non-html template" do
    template = ~s'...<%= link_to "/", "Home" %>...'
    assert_raise CompileError, fn ->
      Wyvern.render_view([], [layers: [{:inline, template}]], [ext: "txt"])
    end
  end
end
