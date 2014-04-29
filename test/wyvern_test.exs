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

  test "layers with sections" do
    base = """
    Hello world. <%= yield :middle %> Interlude. <%= yield %> Footer.
    """

    section = """
    Main content goes here.
    <% content_for :middle do %>This is middle content.<% end %>
    """

    result = """
    Hello world. This is middle content. Interlude. Main content goes here.

     Footer.
    """

    layers = [
      {:inline, base},
      {:inline, section},
    ]
    assert Wyvern.render_view([], [layers: layers])
           == result
  end

  test "unused layer content" do
    layers = [
      {:inline, "top level"},
      {:inline, "sub level <% content_for :top do %>...<% end %>"},
    ]
    assert Wyvern.render_view([name: "people"], [layers: layers])
           == "top level"
  end

  test "transitive sections" do
    layers = [
      {:inline, "top level <%= yield :extra %>"},
      {:inline, "middle level"},
      {:inline, "bottom level <% content_for :extra do %>hello<% end %>"},
    ]
    assert Wyvern.render_view([], [layers: layers])
           == "top level hello"
  end

  test "overriding sections" do
    layers = [
      {:inline, "top level <%= yield :extra %>"},
      {:inline, "middle level <% content_for :extra do %>hello middle<% end %>"},
      {:inline, "bottom level <% content_for :extra do %>hello bottom<% end %>"},
    ]
    assert Wyvern.render_view([], [layers: layers])
           == "top level hello middle"
  end

  #test "transitive content" do
    #layers = [
      #{:inline, "top level <%= yield %>"},
      #{:inline, "middle level"},
      #{:inline, "bottom level"},
    #]
    #assert Wyvern.render_view([], [layers: layers])
           #== "top level middle levelbottom level"
  #end

  test "full-blown html" do
    model = %{
      title: "Test Page",
      stylesheets: [src: "/css/style1.css", src: "/css/style2.css"],
      scripts: [inline: ~s'console.log("hi")', src: "/ui.js"],
    }

    sub_template =
      "<p>Main content</p><% content_for :head do %><!-- additional head content --><% end %>"
    layers = ["layout", {:inline, sub_template}]

    result = Wyvern.render_view(model, [layers: layers], [views_root: views_root])
    expected = File.read!(Path.join(views_root, "layout_rendered.html.eex"))

    assert result == expected
  end

  defp views_root, do: Path.join([System.cwd(), "test", "fixtures"])
end

defmodule WyvernTest.Helpers do
  use ExUnit.Case

  alias Wyvern.View.Helpers, as: H

  test "render partial helper" do
    assert H.render(partial: "about", config: [partials_root: partials_root])
           == "hi hi hi\n"
  end

  test "render script tag helper" do
    assert H.render({:src, "file.js"}, tag: :script)
           == ~s'<script src="file.js" type="application/javascript"></script>'

    assert H.render({:inline, "console.log();"}, tag: :script)
           == ~s'<script type="application/javascript">console.log();</script>'

    scripts = [
      ~s'<script src="1.js" type="application/javascript"></script>',
      ~s'<script src="2.js" type="application/javascript"></script>',
      ~s'<script type="application/javascript">hello</script>',
    ] |> Enum.join("\n")
    assert H.render([src: "1.js", src: "2.js", inline: "hello"], tag: :script)
           == scripts
  end

  test "render stylesheets tag helper" do
    assert H.render({:src, "style.css"}, tag: :stylesheet)
           == ~s'<link href="style.css" rel="stylesheet">'

    styles = [
      ~s'<link href="/bootstrap.css" rel="stylesheet">',
      ~s'<link href="http://example.com/style.css" rel="stylesheet">',
    ] |> Enum.join("\n")
    files = [src: "/bootstrap.css", src: "http://example.com/style.css"]
    assert H.render(files, tag: :stylesheet) == styles
  end

  test "content_for helper" do
    layers = [
      {:inline, "<%= yield :hello %>"},
      {:inline, "<% content_for :hello do %>hello<% end %>"},
    ]
    assert Wyvern.render_view([], [layers: layers])
           == "hello"
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
