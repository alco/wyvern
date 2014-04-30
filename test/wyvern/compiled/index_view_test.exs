defmodule WyvernTest.ViewTest do
  defmodule IndexView do
    use Wyvern.View, [
      views_root: "test/fixtures",
      layers: ["layout", "index"],
    ]
  end

  use ExUnit.Case

  import Wyvern.TestHelpers

  test "2-level compiled view" do
    model = %{
      title: "Test Page",
      stylesheets: [src: "/css/style1.css", src: "/css/style2.css"],
      scripts: [inline: ~s'console.log("hi")', src: "/ui.js"],
    }

    assert IndexView.render(model) == File.read!(Path.join(views_root, "layout_rendered.html"))
  end
end
