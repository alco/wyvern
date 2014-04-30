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
