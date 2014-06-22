defmodule Wyvern.Mixfile do
  use Mix.Project

  def project do
    [app: :wyvern,
     version: "0.0.1",
     elixir: "~> 0.14.0"]
  end

  def application do
    [mod: {Wyvern, []}]
  end
end
