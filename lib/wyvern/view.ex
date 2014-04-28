defmodule Wyvern.View do
  @templates_root "lib/:app/views/templates"

  defmacro __using__(_opts) do
    quote context: nil do
      @before_compile unquote(__MODULE__)
    end
  end

  defrecord Page, [
    name: "",
    title: nil,
    stylesheets: [],
    scripts: [],
    templates: [],
    model: [versions: []],
    has_settings: false,
  ]

  def render([partial: name]) do
    Wyvern.render_partial(name)
  end

  def render(_thing, _opts) do
  end

  defmacro content_for(target, [do: code]) do
    Process.put({:content, target}, code)
    #IO.puts "content_for #{target}"
    #IO.inspect code
    nil
  end

  defmacro __before_compile__(env=Macro.Env[module: mod]) do
    stylesheets = Module.get_attribute(env.module, :stylesheets)
    scripts = Module.get_attribute(env.module, :scripts)
    #templates = Module.get_attribute(env.module, :templates)

    template_filename = module_to_template(mod)
    template_path = Path.join(@templates_root, template_filename)

    body = EEx.compile_file(template_path, []) #line: 1, engine: Wyvern.SuperSmartEngine])

    quote context: nil do
      require EEx

      import Wyvern.View, only: [render: 1, render: 2, content_for: 2]

      def render(_engine, model) do
        IO.puts "making page"
        page = unquote(__MODULE__).Page[
          stylesheets: unquote(stylesheets),
          scripts: unquote(scripts),
          templates: templates(model),
          model: model,
        ]
        IO.puts "including body"
        tmp = unquote(body)
        IO.puts "done deal"
        tmp
      end
    end
  end

  defp module_to_template(modname) do
    last_component = Module.split(modname) |> List.last
    [_, name] = Regex.run(~r/^([[:alpha:]]+)View$/, last_component)
    downcase_camel(name) <> ".html.eex"
  end

  defp downcase_camel(<<c, rest::binary>>) do
    do_downcase_camel(String.downcase(<<c>>) <> rest, "")
  end

  defp do_downcase_camel(<<c, rest::binary>>, acc) when c >= ?A and c <= ?Z do
    do_downcase_camel(rest, Enum.join([acc, "_", <<c-?A+?a>>]))
  end

  defp do_downcase_camel(<<c, rest::binary>>, acc) do
    do_downcase_camel(rest, acc <> <<c>>)
  end

  defp do_downcase_camel(<<>>, acc) do
    acc
  end
end
