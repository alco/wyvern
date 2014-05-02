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
    attrs = %{
      title: "Test Page",
      stylesheets: [src: "/css/style1.css", src: "/css/style2.css"],
      scripts: [inline: ~s'console.log("hi")', src: "/ui.js"],
    }

    result   = IndexView.render(attrs)
    expected = File.read!(Path.join(views_root, "layout_rendered.html"))
    assert result == expected
  end
end
