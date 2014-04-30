defmodule Wyvern.SuperSmartEngine do
  def handle_body(body, _state) do
    #IO.puts "printing body" #IO.puts "handle_body #{inspect body}"
    #IO.puts Macro.to_string(body)
    body
  end

  def handle_text(buffer, text, state) do
    #IO.puts "handle_text ... #{inspect text}"
    q = quote do
      unquote(buffer) <> unquote(text)
    end
    { q, state }
  end

  def handle_expr(buffer, marker, expr, state) do
    #IO.puts "handle_expr ... \"=\" #{inspect expr}"
    expr = transform(expr, state)

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
    { q, state }
  end


  defp transform({:yield, _, nil}, _) do
    {:yield, nil}
  end

  defp transform({:yield, _, [section]}, _) do
    {:yield, section}
  end

  defp transform({:content_for, _, [section, [do: quoted]]}, {pid, _config}) do
    send(pid, {:fragment, [{section, quoted}]})
    nil
  end

  defp transform({:include, _, [partial]}, state) do
    Wyvern.render_partial(partial, state)
  end

  defp transform(other, _), do: other
end
