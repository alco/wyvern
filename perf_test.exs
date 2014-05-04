defmodule WyvernTest.Performance do
  def start(n, precompile?) do
    base = """
    Hello world. This is a test comparing the speed of repeated
    template rendering with and without using autocompilation.

    <%= yield %>

    Below this line is some additional content from child templates.
    ---
    <%= yield :extra %>
    """

    child = """
    <% content_for :extra do %>Extra content take 1.<% end %>
    This is a child of the base layout.

    <%= yield %>
    """

    grandchild = """
    This is a leaf layer of the hierarchy.
    <% content_for :extra do %>
    Extra content take 2.
    <% end %>
    """

    layers = [
      {:inline, base},
      {:inline, child},
      {:inline, grandchild},
    ]

    IO.puts "Rendering without autocompilation #{n} times"
    {t1, output1} = :timer.tc(fn -> repeat(n, fn -> Wyvern.render_view(layers, autocompile: false) end) end)
    IO.puts "#{t1 / 1000} ms"

    IO.puts "Rendering with autocompilation #{n} times"
    if precompile? do
      IO.puts "(and precompilation)"
      Wyvern.render_view(layers, autocompile: true)
    end
    {t2, output2} = :timer.tc(fn -> repeat(n, fn -> Wyvern.render_view(layers, autocompile: true) end) end)
    IO.puts "#{t2 / 1000} ms"

    IO.puts "Ratio = #{t1 / t2}"

    if output1 != output2 do
      raise RuntimeError, message: "Outputs do not match"
    end
  end

  defp repeat(1, f) do
    f.()
  end

  defp repeat(n, f) do
    f.()
    repeat(n-1, f)
  end
end

n = 10
precompile = true
WyvernTest.Performance.start n, precompile
