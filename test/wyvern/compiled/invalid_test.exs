defmodule WyvernTest.InvalidTest do
  use ExUnit.Case

  test "layout as view" do
    assert_raise ArgumentError, fn ->
      defmodule SampleView do
        use Wyvern.View, [
          layers: [{:inline, "<%= yield %>"}],
        ]
      end
    end

    assert_raise ArgumentError, fn ->
      defmodule SampleView do
        use Wyvern.View, [
          layers: [{:inline, "<%= yield :head %>"}],
        ]
      end
    end
  end

  test "view as layout" do
    assert_raise ArgumentError, fn ->
      defmodule SampleLayout do
        use Wyvern.Layout, [
          layers: [{:inline, "hello world <% content_for :head do %>...<% end %>"}],
        ]
      end
    end
  end
end
