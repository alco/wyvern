ExUnit.start

defmodule Wyvern.TestHelpers do
  def views_root, do: Path.join([System.cwd(), "test", "fixtures"])
end
