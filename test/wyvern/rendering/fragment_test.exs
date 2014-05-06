defmodule WyvernTest.FragmentTest do
  use ExUnit.Case

  # basic sanity check tests of the intended usage
  test "layers with fragments" do
    base = """
    Hello world. <%= yield :middle %> Interlude. <%= yield %> Footer.
    """

    section = """
    Main content goes here.
    <% content_for :middle do %>This is middle content.<% end %>
    """

    layers = [
      {:inline, base},
      {:inline, section},
    ]

    expected = """
    Hello world. This is middle content. Interlude. Main content goes here.

     Footer.
    """

    assert Wyvern.render_view(layers) == expected
  end

  test "yields with no content" do
    assert Wyvern.render_view({:inline, "<%= yield %>"}) == ""
    assert Wyvern.render_view({:inline, "<%= yield :head %>"}) == ""

    layers = [
      {:inline, "<%= yield %>"},
      {:inline, "<%= yield :head %>...<%= yield %>"},
    ]
    Wyvern.render_view(layers) == "..."
  end

  test "only named yields in layout" do
    layers = [
      {:inline, "Hello world.<%= yield :head %>"},
      {:inline, "<% content_for :head do %>hi<% end %>Main content"},
    ]
    assert Wyvern.render_view(layers) == "Hello world.hi"
  end

  test "transitive fragments" do
    layers = [
      {:inline, "top;<%= yield :extra %>"},
      {:inline, "middle,<%= yield %>,level"},
      {:inline, "bottom <% content_for :extra do %>hello<% end %>"},
    ]
    assert Wyvern.render_view(layers) == "top;hello"
  end

  test "concatenating fragments" do
    layers = [
      {:inline, "top;<%= yield :extra %>"},
      {:inline, "middle,<%= yield %><% content_for :extra do %>[hello middle]<% end %>"},
      {:inline, "bottom <% content_for :extra do %>[hello bottom]<% end %>"},
    ]
    assert Wyvern.render_view(layers) == "top;[hello middle][hello bottom]"
  end

  test "interleaving fragments" do
    layers = [
      {:inline, "top;<%= yield :extra %>;<%= yield %>"},
      {:inline, "middle,<% content_for :extra do %>[hello middle]<% end %>,<%= yield :extra %>"},
      {:inline, "bottom <% content_for :extra do %>[hello bottom]<% end %>"},
    ]

    expected = "top;[hello middle][hello bottom];middle,,[hello bottom]"
    assert Wyvern.render_view(layers) == expected
  end

  test "immediate fragments" do
    layers = [
      {:inline, "top;<%= yield :extra %>;<%= yield %>"},
      {:inline, "middle,<%= yield :extra %>,<% content_for :extra do %>[hello middle]<% end %><%= yield %>"},
      {:inline, "bottom <% content_for :extra do %>[hello bottom]<% end %>"},
    ]

    expected = "top;[hello middle][hello bottom];middle,[hello bottom],bottom "
    assert Wyvern.render_view(layers) == expected
  end

  test "attributes in fragments" do
    layers = [
      {:inline, "<%= yield %><%= yield :head %>"},
      {:inline, "<% content_for :head do %><%= @hello %><% end %>"},
    ]
    assert Wyvern.render_view(layers, attrs: [hello: "hi"]) == "hi"
  end


  ## error cases

  test "no yield in layout" do
    layers = [
      {:inline, "Hello world."},
      {:inline, "Main content"},
    ]
    # FIXME: be more specific about the exception
    assert_raise ArgumentError, fn ->
      Wyvern.render_view(layers)
    end

    layers = [
      {:inline, "Hello world"},
      {:inline, "<% content_for :head do %>content<% end %>"},
    ]
    assert_raise ArgumentError, fn ->
      Wyvern.render_view(layers)
    end
  end

  test "bad usage of yield and content_for" do
    # FIXME: be more specific about the exception
    assert_raise RuntimeError, fn ->
      Wyvern.render_view({:inline, "<% yield %>"})
    end

    # FIXME: be more specific about the exception
    assert_raise RuntimeError, fn ->
      Wyvern.render_view({:inline, "<% yield :head %>"})
    end

    # FIXME: be more specific about the exception
    assert_raise RuntimeError, fn ->
      Wyvern.render_view({:inline, "<%= content_for :head do %><% end %>"})
    end
  end
end
