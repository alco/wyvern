defmodule WyvernTest.PartialsTest do
  use ExUnit.Case

  defp render_view(layers, config \\ []) do
    # use proper views_root setting for all tests
    Wyvern.render_view(layers, [views_root: WyvernTest.TestHelpers.views_root] ++ config)
  end


  test "partial in template" do
    template = """
    Hello.
    <%= include "/about" %>
    ---
    <%= include "/hello" %>
    """

    expected = """
    Hello.
    hi hi hi

    ---
    Hello people

    """

    config = [attrs: [name: "people"]]
    assert render_view({:inline, template}, config) == expected
  end

  test "partials and layers" do
    layers = [
      {:inline, ~s'Hello, <%= include "/content_yield" %>'},
      {:inline, "<% content_for :content do %><sample content><% end %>"},
    ]
    expected = "Hello, This content is from :content:\n<sample content>\n"
    assert render_view(layers) == expected
  end

  test "partial content_for" do
    layers = [
      {:inline, ~s'Hello, <%= include "/content_yield" %>'},
      {:inline, ~s'<%= include "/content_for" %>'},
    ]
    expected = "Hello, This content is from :content:\ncustom content\n"
    assert render_view(layers) == expected
  end


  ## error cases

  test "bad partial in template" do
    template = ~s'<%= include "non-existent" %>'
    # FIXME: be more specific about the exception
    assert_raise ArgumentError, fn ->
      Wyvern.render_view({:inline, template})
    end
  end
end
