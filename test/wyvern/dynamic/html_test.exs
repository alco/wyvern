defmodule WyvernTest.HTML do
  use ExUnit.Case

  import Wyvern.TestHelpers

  test "full-blown html" do
    attrs = %{
      title: "Test Page",
      stylesheets: [src: "/css/style1.css", src: "/css/style2.css"],
      scripts: [inline: ~s'console.log("hi")', src: "/ui.js"],
      cond: true,
      then: "then",
    }

    layers = ["layout", "index"]

    config = [views_root: views_root, attrs: attrs]
    result = Wyvern.render_view(layers, config)
    expected = File.read!(Path.join(views_root, "layout_rendered.html"))

    assert result == expected
  end
end

defmodule WyvernTest.HTMLHelpers do
  use ExUnit.Case

  alias Wyvern.View.HTMLHelpers, as: H

  test "render script tag helper" do
    assert H.render_tag({:src, "file.js"}, :script)
           == ~s'<script src="file.js" type="application/javascript"></script>'

    assert H.render_tag({:inline, "console.log();"}, :script)
           == ~s'<script type="application/javascript">console.log();</script>'

    scripts = [
      ~s'<script src="1.js" type="application/javascript"></script>',
      ~s'<script src="2.js" type="application/javascript"></script>',
      ~s'<script type="application/javascript">hello</script>',
    ] |> Enum.join("\n")
    assert H.render_tag([src: "1.js", src: "2.js", inline: "hello"], :script)
           == scripts
  end

  test "render stylesheets tag helper" do
    assert H.render_tag({:src, "style.css"}, :stylesheet)
           == ~s'<link href="style.css" rel="stylesheet">'

    styles = [
      ~s'<link href="/bootstrap.css" rel="stylesheet">',
      ~s'<link href="http://example.com/style.css" rel="stylesheet">',
    ] |> Enum.join("\n")
    files = [src: "/bootstrap.css", src: "http://example.com/style.css"]
    assert H.render_tag(files, :stylesheet) == styles
  end

  test "tags in template" do
    template = """
    Hello.
    <%= render @scripts, tag: :script %>
    ---
    <%= render @styles, tag: :stylesheet %>
    End.
    """

    scripts = [{:inline, "console.log('hi')"}, {:src, "jquery.js"}]
    styles = {:src, "/default.css"}

    expected = """
    Hello.
    <script type="application/javascript">console.log('hi')</script>
    <script src="jquery.js" type="application/javascript"></script>
    ---
    <link href="/default.css" rel="stylesheet">
    End.
    """

    result = Wyvern.render_view({:inline, template}, attrs: [scripts: scripts, styles: styles])
    assert result == expected
  end

  test "link helper" do
    result = H.link_to("/index.html", "Home")
    assert result == ~s'<a href="/index.html">Home</a>'

    result = H.link_to("http://example.com", " example ")
    assert result == ~s'<a href="http://example.com"> example </a>'

    result = H.link_to("#", " example ", class: "active", id: "unique")
    assert result == ~s'<a href="#" class="active" id="unique"> example </a>'
  end

  test "link helper in template" do
    template = ~s'...<%= link_to "/", "Home" %>...'
    result = Wyvern.render_view({:inline, template})
    assert result == ~s'...<a href="/">Home</a>...'

    template = ~s'...<%= link_to "/", "Home", id: "home" %>...'
    result = Wyvern.render_view({:inline, template})
    assert result == ~s'...<a href="/" id="home">Home</a>...'
  end

  #test "link in non-html template" do
    #template = ~s'...<%= link_to "/", "Home" %>...'
    #assert_raise CompileError, fn ->
      #Wyvern.render_view({:inline, template}, ext: "txt")
    #end
  #end
end
