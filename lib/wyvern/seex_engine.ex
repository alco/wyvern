defmodule Wyvern.SuperSmartEngine do
  def handle_body(body, _config) do
    #IO.puts "printing body" #IO.puts "handle_body #{inspect body}"
    #IO.puts Macro.to_string(body)
    body
  end

  def handle_text("", text, config), do:
    handle_text({"", []}, text, config)

  def handle_text({buffer, fragments}, text, config) do
    #IO.puts "handle_text ... #{inspect text}"
    q = quote do
      unquote(buffer) <> unquote(text)
    end
    { {q, fragments}, config }
  end

  def handle_expr("", marker, expr, config), do:
    handle_expr({"", []}, marker, expr, config)

  def handle_expr({buffer, fragments}, marker, expr, config) do
    #IO.puts "handle_expr ... \"=\" #{inspect expr}"
    {expr, fragment} = case transform(expr, config) do
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
    { {q, new_fragments}, config }
  end

  defp transform({:yield, _, nil}, _config) do
    quote context: nil do
      _content
    end
  end

  defp transform({:yield, _, [section]}, _config) do
    {:yield, section}
  end

  defp transform({:content_for, _, [section, [do: {quoted, _}]]}, _config) do
    {:fragment, [{section, quoted}]}
  end

  defp transform({:include, _, [partial]}, config) do
    Wyvern.render_partial(partial, config)
  end

  defp transform(other, _config), do: other
end
