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

    config = [views_root: views_root, attrs: [name: "people"]]
    assert Wyvern.render_view({:inline, template}, config) == result
  end

  test "partials and layers" do
    layers = [
      {:inline, ~s'Hello, <%= include "content_yield" %>'},
      {:inline, "<% content_for :content do %><sample content><% end %>"},
    ]
    result = "Hello, This content is from :content:\n<sample content>\n"

    assert Wyvern.render_view(layers, views_root: views_root) == result
  end

  test "partial content_for" do
    layers = [
      {:inline, ~s'Hello, <%= include "content_yield" %>'},
      {:inline, ~s'<%= include "content_for" %>'},
    ]
    result = "Hello, This content is from :content:\ncustom content\n"

    assert Wyvern.render_view(layers, views_root: views_root) == result
  end
end
