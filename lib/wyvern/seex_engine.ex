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
    {expr, new_fragments} = transform(expr, fragments, config)

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
    { {q, new_fragments}, config }
  end

  defp transform({:yield, _, nil}, fragments, _config) do
    q = quote context: nil do
      _content
    end
    {q, fragments}
  end

  defp transform({:yield, _, [section]}, fragments, _config) do
    { {:yield, section}, fragments }
  end

  defp transform({:content_for, _, [section, [do: {quoted, _}]]}, fragments, _config) do
    frag = [{section, quoted}]
    {nil, Wyvern.View.Helpers.merge_fragments(fragments, frag)}
  end

  defp transform({:include, _, [partial]}, fragments, config) do
    {quoted, partial_fragments} = Wyvern.render_partial(partial, config)
    {quoted, Wyvern.View.Helpers.merge_fragments(fragments, partial_fragments)}
  end

  defp transform(other, fragments, _config), do: {other, fragments}
end
