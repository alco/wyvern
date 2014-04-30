defmodule Wyvern.SuperSmartEngine do
  use EEx.TransformerEngine

  def handle_body(body) do
    #IO.puts "printing body" #IO.puts "handle_body #{inspect body}"
    #IO.puts Macro.to_string(body)
    body
  end

  def handle_text("", text) do
    handle_text({"", []}, text)
  end

  def handle_text({buffer, fragments}, text) do
    #IO.puts "handle_text ... #{inspect text}"
    q = quote do
      unquote(buffer) <> unquote(text)
    end
    {q, fragments}
  end

  def handle_expr("", marker, expr) do
    handle_expr({"", []}, marker, expr)
  end

  def handle_expr({buffer, fragments}, marker, expr) do
    #IO.puts "handle_expr ... \"=\" #{inspect expr}"
    {expr, fragment} = case transform(expr) do
      {:fragment, fragment} -> {nil, fragment}
      quoted                -> {quoted, []}
    end

    q = case marker do
      "=" ->
        quote do
          tmp = unquote(buffer)
          tmp <> to_string(unquote(expr))
        end

      "" ->
        quote do
          tmp = unquote(buffer)
          unquote(expr)
          tmp
        end
    end
    new_fragments = Wyvern.View.Helpers.merge_fragments(fragments, fragment)
    {q, new_fragments}
  end

  defp transform({:yield, _, nil}) do
    quote context: nil do
      _content
    end
  end

  defp transform({:yield, _, [section]}) do
    {:yield, section}
  end

  defp transform({:content_for, _, [section, [do: {quoted, _}]]}) do
    {:fragment, [{section, quoted}]}
  end

  defp transform(other), do: other
end
