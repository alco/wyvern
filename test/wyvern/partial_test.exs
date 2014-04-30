defmodule WyvernTest.Partials do
  use ExUnit.Case

  import Wyvern.TestHelpers

  test "partial in template" do
    template = """
    Hello.
    <%= include "about" %>
    ---
    <%= include "hello" %>
    """

    result = """
    Hello.
    hi hi hi

    ---
    Hello people

    """

    layers = [layers: [{:inline, template}]]
    config = [partials_root: partials_root]
    assert Wyvern.render_view([name: "people"], layers, config)
           == result
  end

  test "partials and layers" do
    layers = [
      {:inline, ~s'Hello, <%= include "content_yield" %>'},
      {:inline, "<% content_for :content do %><sample content><% end %>"},
    ]
    result = "Hello, This content is from :content:\n<sample content>\n"

    assert Wyvern.render_view([], [layers: layers], [partials_root: partials_root])
           == result
  end

  test "partial content_for" do
    layers = [
      {:inline, ~s'Hello, <%= include "content_yield" %>'},
      {:inline, ~s'<%= include "content_for" %>'},
    ]
    result = "Hello, This content is from :content:\ncustom content\n"

    assert Wyvern.render_view([], [layers: layers], [partials_root: partials_root])
           == result
  end
end
