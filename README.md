Wyvern
======

Wyvern is a view engine.

It can be used as is to add view rendering capabilities to your web application
or it can be built upon to provide a full-featured MVC stack.


## Goals

Wyvern aims to provide a minimal basis for others to build upon. Hence its
properties:

* Focuses entirely on view rendering. It doesn't provide routing or similar
  conveniences found in MVC frameworks.

* Based on simple principles that make it easy to understand how it works.

* Configurable and unobtrusive to allow for integration with projects that are
  larger in scope.


## Usage

This section serves as a guide on how to get started with Wyvern in your web
application. If you are interested in integrating Wyvern into a web framework
(or a project similar in scope), see `doc/Building-on-top-of-Wyvern.md`.

The complete reference guide can be found in `doc/reference/`.


### Dynamic template rendering

The dumbest way to render a template is using the `Wyvern.render_view`
function:

```elixir
Wyvern.render_view({:inline, "plain text content"}) |> IO.puts
---
plain text content
```

Data is passed into templates via the `model` parameter.

```elixir
Wyvern.render_view({:inline, "hello <%= model[:name] %>"}, model: [name: "world"])
|> IO.puts
---
hello world
```

The first argument to `render_view` can be a text template (passed in as a tuple
`{:inline, <text>}`), a string (interpreted as a file name), or a list of those
things.

When passing a list, Wyvern renders it as a list of layers, starting from the
first one and including into it the specified content from subsequent layers:

```elixir
layout = "top-level content
<%= yield %>
some more content

# content from sublayer:
<%= yield :extra %>"

index = "main sublayer content
<% content_for :extra do %>hello from index<% end %>"

Wyvern.render_view(Enum.map([layout, index], &{:inline, &1})) |> IO.puts
---
top-level content
main sublayer content

some more content

# content from sublayer:
hello from index
```

When passed in, the model will be shared accross all layers:

```elixir
top = "hello <%= model[:name] %> and <%= yield :other_name %>"
sub = "ignored content"
subsub = "<% content_for :other_name do %>Andrew<% end %>"

config = [model: [name: "world"]]
Wyvern.render_view(Enum.map([top, sub], &{:inline, &1}), config) |> IO.puts
---
hello world and Andrew
```

Notice that the content from `sub` does not show up in the rendered text because
`top` does not have a `yield` placeholder.

Wyvern starts rendering from the first layer and treats each layer as a
blueprint for the expected result. Since `top` does not include any content
using `yield`, subsequent layer does not get "pasted" into it.


### Templates in files

Wyvern is designed to be used as a dependency in projects managed by mix. By
default it expects your `$views_root` directory to have the following directory
structure when looking for templates:

```
layouts/
  layout.html.eex
partials/
  _about.html.eex
templates/
  index.html.eex
```

`views_root` is a configuration variable. It is set to `<app root>/lib/<app
name>/views` by default.




First, let's get the terminology straight.
The dumbest way to render a view

### Compiled views

The recommended wa
In contrast with dynamically rendered templates,

### Adding a view server

A view server is a component that keeps centralized information about the view
hierarchy of your application. Its use is optional, but it can provide a
convenient way to manage your views in a web framework-less application
setting.

---

What follows next is a set of different use cases and description of how Wyvern
applies to them.


### 1. Rendering templates to static assets upfront

Probably the easiest thing to do with a view engine is to use it as a compiler
to convert a set of templates and other data associated with them into static
files (HTML, etc.) that can be served by a generic web server or hosted on a
CDN.

Wyvern lets you do this at app launch or at compile time. It will take view
definitions as described in Elixir code and render them into final content,
either in memory or to disk depending on the configuration.

See the project at https://github.com/alco/wyvern-examples/prerender for an
example of this workflow.


### 2. On-demand rendering with caching

This workflow works as follows. You always call the `Wyvern.render_view`
function (or `render` function on your view) to get the rendered view back.
Depending on the way caching has been configured, it may skip the rendering and
return cached content.

Keep in mind that Wyvern doesn't take your application's models into account,
it only relies on the cache configuration to decide whether it should redo
the rendering of a particular view.

See sample project at https://github.com/alco/wyvern-examples/ondemand.


### 3. Generating view modules automatically

By adopting a small set of conventions Wyvern can take your templates and
generate views (Elixir modules) that can be afterwards added to source control
and further modified.

See the project at https://github.com/alco/wyvern-examples/autogen for an
example of this.
