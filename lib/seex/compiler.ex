# This is a modified version of the original source file at
# https://github.com/elixir-lang/elixir/blob/master/lib/eex/lib/eex/compiler.ex
# which is released under the following license

# Copyright 2012-2013 Plataformatec.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

defmodule SEEx.Compiler do
  @moduledoc false

  @doc """
  This is the compilation entry point. It glues the tokenizer
  and the engine together by handling the tokens and invoking
  the engine every time a full expression or text is received.
  """
  def compile(source, user_data, opts) do
    file   = opts[:file] || "nofile"
    line   = opts[:line] || 1
    tokens = EEx.Tokenizer.tokenize(source, line)
    state  = %{engine: opts[:engine],
               file: file, line: line, quoted: [], start_line: nil,
               user_data: user_data}
    generate_buffer(tokens, "", [], state)
  end

  # Generates the buffers by handling each expression from the tokenizer

  defp generate_buffer([{:text, chars}|t], buffer, scope, state) do
    {buffer, new_data} = state.engine.handle_text(buffer, String.from_char_data!(chars), state[:user_data])
    generate_buffer(t, buffer, scope, Map.put(state, :user_data, new_data))
  end

  defp generate_buffer([{:expr, line, mark, chars}|t], buffer, scope, state) do
    expr = Code.string_to_quoted!(chars, [line: line, file: state.file])
    {buffer, new_data} = state.engine.handle_expr(buffer, mark, expr, state[:user_data])
    generate_buffer(t, buffer, scope, Map.put(state, :user_data, new_data))
  end

  defp generate_buffer([{:start_expr, start_line, mark, chars}|t], buffer, scope, state) do
    {contents, line, t} = look_ahead_text(t, start_line, chars)
    {contents, t} = generate_buffer(t, "", [contents|scope],
                                    %{state | quoted: [], line: line, start_line: start_line})
    {buffer, new_data} = state.engine.handle_expr(buffer, mark, contents, state[:user_data])
    generate_buffer(t, buffer, scope, Map.put(state, :user_data, new_data))
  end

  defp generate_buffer([{:middle_expr, line, _, chars}|t], buffer, [current|scope], state) do
    {wrapped, state} = wrap_expr(current, line, buffer, chars, state)
    generate_buffer(t, "", [wrapped|scope], %{state | line: line})
  end

  defp generate_buffer([{:end_expr, line, _, chars}|t], buffer, [current|_], state) do
    {wrapped, state} = wrap_expr(current, line, buffer, chars, state)
    tuples = Code.string_to_quoted!(wrapped, [line: state.start_line, file: state.file])
    buffer = insert_quoted(tuples, state.quoted)
    {buffer, t}
  end

  defp generate_buffer([{:end_expr, line, _, chars}|_], _buffer, [], _state) do
    raise EEx.SyntaxError, message: "unexpected token: #{inspect chars} at line #{inspect line}"
  end

  defp generate_buffer([], buffer, [], state) do
    state.engine.handle_body(buffer, state[:user_data])
  end

  defp generate_buffer([], _buffer, _scope, _state) do
    raise EEx.SyntaxError, message: "unexpected end of string. expecting a closing <% end %>."
  end

  # Creates a placeholder and wrap it inside the expression block

  defp wrap_expr(current, line, buffer, chars, state) do
    new_lines = List.duplicate(?\n, line - state.line)
    key = length(state.quoted)
    placeholder = '__EEX__(' ++ integer_to_list(key) ++ ');'
    {current ++ placeholder ++ new_lines ++ chars,
     %{state | quoted: [{key, buffer}|state.quoted]}}
  end

  # Look text ahead on expressions

  defp look_ahead_text([{:text, text}, {:middle_expr, line, _, chars}|t]=list, start, contents) do
    if only_spaces?(text) do
      {contents ++ text ++ chars, line, t}
    else
      {contents, start, list}
    end
  end

  defp look_ahead_text(t, start, contents) do
    {contents, start, t}
  end

  defp only_spaces?(chars) do
    Enum.all?(chars, &(&1 in [?\s, ?\t, ?\r, ?\n]))
  end

  # Changes placeholder to real expression

  defp insert_quoted({:__EEX__, _, [key]}, quoted) do
    {^key, value} = List.keyfind quoted, key, 0
    value
  end

  defp insert_quoted({left, line, right}, quoted) do
    {insert_quoted(left, quoted), line, insert_quoted(right, quoted)}
  end

  defp insert_quoted({left, right}, quoted) do
    {insert_quoted(left, quoted), insert_quoted(right, quoted)}
  end

  defp insert_quoted(list, quoted) when is_list(list) do
    Enum.map list, &insert_quoted(&1, quoted)
  end

  defp insert_quoted(other, _quoted) do
    other
  end
end
