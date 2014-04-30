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
    {expr, new_fragments} = transform(expr, config)
    new_fragments = Wyvern.View.Helpers.merge_fragments(fragments, new_fragments)

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

  defp transform({:yield, _, nil}, _config) do
    q = quote context: nil do
      _content
    end
    {q, []}
  end

  defp transform({:yield, _, [section]}, _config) do
    { {:yield, section}, [] }
  end

  defp transform({:content_for, _, [section, [do: {quoted, _}]]}, _config) do
    {nil, [{section, quoted}]}
  end

  defp transform({:include, _, [partial]}, config) do
    Wyvern.render_partial(partial, config)
  end

  defp transform({f, meta, args}, _config) do
    {{f, meta, strip_args(args)}, []}
  end

  defp transform(other, _config), do: {other, []}


  defp strip_args(nil), do: nil
  defp strip_args([]), do: []
  defp strip_args(a) when is_atom(a), do: a

  defp strip_args(args), do:
    strip_args(args, [])

  defp strip_args([], acc), do:
    Enum.reverse(acc)

  defp strip_args([[do: {quoted, _}] | rest], acc), do:
    strip_args(rest, [[do: quoted] | acc])

  defp strip_args([other|rest], acc), do:
    strip_args(rest, [other|acc])
end
