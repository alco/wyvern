defmodule Wyvern.SuperSmartEngine do
  use EEx.TransformerEngine

  def handle_body(body) do
    #IO.puts "printing body" #IO.puts "handle_body #{inspect body}"
    #IO.puts Macro.to_string(body)
    body
  end

  def handle_text(buffer, text) do
    #IO.puts "handle_text ... #{inspect text}"
    quote do
      unquote(buffer) <> unquote(text)
    end
  end

  def handle_expr(buffer, "=", expr) do
    #IO.puts "handle_expr ... \"=\" #{inspect expr}"
    expr = transform(expr)

    quote do
      #IO.puts "matching = #{inspect buffer}"
      tmp = unquote(buffer)
      tmp <> to_string(unquote(expr))
    end
  end

  def handle_expr(buffer, "", expr) do
    #IO.puts "handle_expr ... \"\" #{inspect expr}"
    expr = transform(expr)

    quote do
      #IO.puts "matching .."
      tmp = unquote(buffer)
      unquote(expr)
      tmp
    end
  end

  defp transform({:yield, _, nil}) do
    quote context: nil do
      _context[:content]
    end
  end

  defp transform({:yield, _, [section]}) do
    Process.get({:content, section})
  end

  defp transform(other), do: other
end
