defmodule Wyvern.SuperSmartEngine do
  def handle_body(body, _state) do
    #IO.puts "printing body" #IO.puts "handle_body #{inspect body}"
    #IO.puts Macro.to_string(body)
    body
  end

  def handle_text(buffer, text, state) do
    #IO.puts "handle_text ... #{inspect text}"
    q = quote context: :"wyvern-view-fragment" do
      unquote(buffer) <> unquote(text)
    end
    { q, state }
  end

  def handle_expr(buffer, marker, expr, state) do
    #IO.puts "handle_expr ... \"=\" #{inspect expr}"
    expr = transform(expr, state) |> validate_expr(marker)

    q = case marker do
      "=" ->
        quote context: :"wyvern-view-fragment" do
          tmp = unquote(buffer)
          tmp <> to_string(unquote(expr))
        end

      "" ->
        quote context: :"wyvern-view-fragment" do
          tmp = unquote(buffer)
          unquote(expr)
          tmp
        end
    end
    { q, state }
  end


  defp transform({:yield, _, nil}, {pid, _config}) do
    send(pid, :yield)
    {{:yield, nil}}
  end

  defp transform({:yield, _, [section]}, {pid, _config}) do
    send(pid, :yield)
    {{:yield, section}}
  end

  defp transform({:content_for, _, [section, [do: quoted]]}, {pid, _config}) do
    send(pid, {:fragment, [{section, quoted}]})
    {:content_for}
  end

  defp transform({:include, _, [partial]}, state) do
    Wyvern.render_partial(partial, state)
  end

  defp transform(other, _) do
    replace_attr_refs(other)
  end


  defp validate_expr({:content_for}, marker) do
    if marker == "=" do
      raise RuntimeError, message: "content_for cannot be used with '='"
    end
    # intentionally return nil
  end

  defp validate_expr({{:yield, _}}, marker) when marker != "=" do
    raise RuntimeError, message: "yield has to be used with '=', e.g. <%= yield %>"
  end

  defp validate_expr(other, _), do: other


  defp replace_attr_refs({:@, _, [{name, _, atom}]})
                                        when is_atom(name) and is_atom(atom) do
    quote [context: :"wyvern-view-fragment"], do: attrs[unquote(name)]
  end

  defp replace_attr_refs({f, meta, args}) when is_list(args) do
    {replace_attr_refs(f), meta, replace_attr_refs(args)}
  end

  defp replace_attr_refs({a, b}) do
    {replace_attr_refs(a), replace_attr_refs(b)}
  end

  defp replace_attr_refs(list) when is_list(list) do
    Enum.map(list, &replace_attr_refs/1)
  end

  defp replace_attr_refs(other) do
    other
  end
end
