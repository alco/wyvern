ExUnit.start

defmodule WyvernTest.TestHelpers do
  def views_root, do: Path.join([System.cwd(), "test", "fixtures"])
end
