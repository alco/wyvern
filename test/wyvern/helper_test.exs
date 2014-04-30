defmodule WyvernTest.Helpers do
  use ExUnit.Case

  alias Wyvern.View.Helpers, as: H

  test "render partial helper" do
    assert H.render(partial: "about", config: [partials_root: partials_root])
           == "hi hi hi\n"
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
