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
    assert Wyvern.render_view([name: "people"], [layers: ["basic"]], [views_root: views_root])
           == "Hello people!\n"
  end

  defp views_root, do: Path.join([System.cwd(), "test", "fixtures"])
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
end

defmodule WyvernTest.Helpers do
  use ExUnit.Case

  alias Wyvern.View.Helpers, as: H

  test "render partial helper" do
    assert H.render(partial: "about", config: [partials_root: partials_root])
           == "hi hi hi\n"
  end

  test "render tag helper" do
    assert H.render({:src, "file.js"}, tag: :script)
           == ~s'<script src="file.js" type="application/javascript"></script>'

    assert H.render({:inline, "console.log();"}, tag: :script)
           == ~s'<script type="application/javascript">console.log();</script>'

    html = [
      ~s'<script src="1.js" type="application/javascript"></script>',
      ~s'<script src="2.js" type="application/javascript"></script>',
      ~s'<script type="application/javascript">hello</script>',
    ]
    assert H.render([src: "1.js", src: "2.js", inline: "hello"], tag: :script)
           == html
  end

  defp partials_root, do: Path.join([System.cwd(), "test", "fixtures", "partials"])
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
