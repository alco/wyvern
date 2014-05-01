defmodule WyvernTest.ViewTest do
  import Wyvern.TestHelpers

  defmodule IndexView do
    use Wyvern.View, [
      views_root: views_root,
      layers: ["layout", "index"],
    ]
  end

  use ExUnit.Case

  test "2-level compiled view" do
    model = %{
      title: "Test Page",
      stylesheets: [src: "/css/style1.css", src: "/css/style2.css"],
      scripts: [inline: ~s'console.log("hi")', src: "/ui.js"],
    }

    assert IndexView.render(model) == File.read!(Path.join(views_root, "layout_rendered.html"))
  end
end
