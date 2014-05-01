# This is a modified version of the original source file at
# https://github.com/elixir-lang/elixir/blob/master/lib/eex/lib/eex.ex
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

defmodule SEEx do
  @doc """
  Get a string `source` and generate a quoted expression
  that can be evaluated by Elixir or compiled to a function.
  """
  def compile_string(source, state, options \\ []) do
    SEEx.Compiler.compile(source, state, options)
  end

  @doc """
  Get a `filename` and generate a quoted expression
  that can be evaluated by Elixir or compiled to a function.
  """
  def compile_file(filename, state, options \\ []) do
    options = Keyword.merge options, [file: filename, line: 1]
    compile_string(File.read!(filename), state, options)
  end
end
