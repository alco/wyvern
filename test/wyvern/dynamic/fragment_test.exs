defmodule WyvernTest.Fragments do
  use ExUnit.Case

  test "layers with fragments" do
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
    assert Wyvern.render_view(layers) == result
  end

  test "leftover fragments" do
    top = "hello <%= @name %> and <%= yield :other_name %>"
    sub = "ignored content"
    subsub = "<% content_for :other_name do %>Andrew<% end %>"

    assert_raise ArgumentError, fn ->
      Wyvern.render_view(Enum.map([top, sub, subsub], &{:inline, &1}))
    end

    config = [attrs: [name: "world"]]

    result = Wyvern.render_view(Enum.map([top, subsub], &{:inline, &1}), config)
    assert result == "hello world and Andrew"

    result = Wyvern.render_view(Enum.map([top], &{:inline, &1}), config)
    assert result == "hello world and "
  end

  test "unused layer content" do
    layers = [
      {:inline, "top level"},
      {:inline, "sub level <% content_for :top do %>...<% end %>"},
    ]
    assert_raise ArgumentError, fn ->
      Wyvern.render_view(layers)
    end
  end

  test "transitive fragments" do
    # FIXME: this doesn't make sense because middle level is ignored
    layers = [
      {:inline, "top level;<%= yield :extra %>"},
      {:inline, "middle,<%= yield %>,level"},
      {:inline, "bottom level <% content_for :extra do %>hello<% end %>"},
    ]
    expected = "top level;hello"
    assert Wyvern.render_view(layers) == expected
  end

  test "concatenating fragments" do
    # FIXME: middle layer is ignored. It should be forbidden to omit <%= yield %>
    layers = [
      {:inline, "top level;<%= yield :extra %>"},
      {:inline, "middle level,<%= yield %><% content_for :extra do %>hello middle<% end %>"},
      {:inline, "bottom level <% content_for :extra do %>hello bottom<% end %>"},
    ]
    assert Wyvern.render_view(layers) == "top level;hello middlehello bottom"
  end

  test "interleaving fragments" do
    layers = [
      {:inline, "top level;<%= yield :extra %>;<%= yield %>"},
      {:inline, "middle level,<% content_for :extra do %>hello middle<% end %>,<%= yield :extra %>"},
      {:inline, "bottom level <% content_for :extra do %>hello bottom<% end %>"},
    ]

    expected = "top level;hello middlehello bottom;middle level,,hello bottom"
    assert Wyvern.render_view(layers) == expected
  end

  test "immediate fragments" do
    layers = [
      {:inline, "top level;<%= yield :extra %>;<%= yield %>"},
      {:inline, "middle level,<%= yield :extra %>,<% content_for :extra do %>hello middle<% end %>"},
      {:inline, "bottom level <% content_for :extra do %>hello bottom<% end %>"},
    ]

    expected = "top level;hello middlehello bottom;middle level,hello bottom,"
    assert Wyvern.render_view(layers) == expected
  end

  test "layout as view" do
    assert Wyvern.render_view({:inline, "<%= yield %>"}) == ""
    assert Wyvern.render_view({:inline, "<%= yield :head %>"}) == ""
  end
end
