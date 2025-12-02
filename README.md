# Datastar for Elixir

An Elixir SDK for the [Datastar](https://data-star.dev) web framework, modeled after the [Go implementation](https://github.com/starfederation/datastar-go).

Datastar enables real-time, server-driven UI updates using Server-Sent Events (SSE). This library provides a clean, idiomatic Elixir interface for streaming dynamic updates to your web applications.

## Features

- 🔄 **Server-Sent Events (SSE)** - Stream real-time updates to connected clients
- 📊 **Signal Management** - Read and patch client-side reactive state
- 🎨 **DOM Manipulation** - Update, append, prepend, and remove HTML elements
- 🚀 **JavaScript Execution** - Execute scripts, log to console, and dispatch events
- 🔀 **Navigation Control** - Redirect and manipulate browser history
- 🎯 **Type-Safe** - Leverages Elixir's pattern matching and type specs

## Installation

Add `datastar_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:datastar_ex, "~> 0.1.0"}
  ]
end
```

## Quick Start

### Basic SSE Streaming

```elixir
defmodule MyAppWeb.DatastarController do
  use MyAppWeb, :controller
  alias Datastar.{SSE, Elements, Signals}

  def stream(conn, _params) do
    conn
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)
    |> SSE.new()
    |> Elements.patch("<div>Hello, Datastar!</div>", selector: "#content")
  end
end
```

### Reading Signals

Signals represent client-side state that can be synchronized with the server:

```elixir
def handle_request(conn, _params) do
  # Read signals from the request
  signals = Datastar.Signals.read(conn)
  count = signals["count"] || 0

  # Update the UI based on signals
  conn
  |> put_resp_content_type("text/event-stream")
  |> send_chunked(200)
  |> SSE.new()
  |> Signals.patch(%{count: count + 1})
  |> Elements.patch("<div>Count: #{count + 1}</div>", selector: "#counter")
end
```

### Patching Elements

Update DOM elements with various merge strategies:

```elixir
sse
# Replace entire element (outer HTML)
|> Elements.patch("<div id='box'>New content</div>", selector: "#box")

# Replace inner HTML only
|> Elements.patch("<p>Inner content</p>", selector: "#container", mode: :inner)

# Append to element
|> Elements.patch("<li>New item</li>", selector: "ul", mode: :append)

# Prepend to element
|> Elements.patch("<li>First item</li>", selector: "ul", mode: :prepend)

# Insert before element
|> Elements.patch("<div>Before</div>", selector: "#target", mode: :before)

# Insert after element
|> Elements.patch("<div>After</div>", selector: "#target", mode: :after)
```

### Removing Elements

```elixir
sse
|> Elements.remove("#temporary-message")
|> Elements.remove_by_id("old-content")
```

### JavaScript Execution

```elixir
sse
# Execute arbitrary JavaScript
|> Script.execute("alert('Hello from server!')")

# Console logging
|> Script.console_log("Debug message")
|> Script.console_error("Error occurred")

# Navigation
|> Script.redirect("/dashboard")
|> Script.replace_url("/new-path")

# Custom events
|> Script.dispatch_custom_event("user-updated", %{id: 123, name: "Alice"})

# Prefetch URLs
|> Script.prefetch(["/dashboard", "/profile"])
```

## API Reference

### Datastar.SSE

Core module for Server-Sent Event streaming:

- `new(conn)` - Create a new SSE generator from a Plug connection
- `send_event(sse, event_type, data, opts)` - Send a custom SSE event
- `send_event!(sse, event_type, data, opts)` - Send event, raising on error
- `closed?(sse)` - Check if the connection is closed

### Datastar.Signals

Manage client-side reactive state:

- `read(conn)` - Read signals from request (query params or body)
- `read_as(conn, module)` - Read signals into a struct
- `patch(sse, signals, opts)` - Update client-side signals
- `patch_raw(sse, json, opts)` - Update with raw JSON
- `patch_if_missing(sse, signals, opts)` - Update only missing signals

**Options:**
- `:only_if_missing` - Only patch signals that don't exist on client
- `:event_id` - Event ID for client tracking
- `:retry` - Retry duration in milliseconds

### Datastar.Elements

Manipulate DOM elements:

- `patch(sse, html, opts)` - Update elements with HTML
- `patchf(sse, format, values, opts)` - Patch with formatted string
- `patch_by_id(sse, id, html, opts)` - Patch element by ID
- `remove(sse, selector, opts)` - Remove elements by selector
- `remove_by_id(sse, id, opts)` - Remove element by ID

**Convenience functions:**
- `patch_outer/3`, `patch_inner/3`, `patch_prepend/3`, `patch_append/3`
- `patch_before/3`, `patch_after/3`, `patch_replace/3`

**Options:**
- `:selector` - CSS selector for target elements (required)
- `:mode` - Patch mode (`:outer`, `:inner`, `:append`, `:prepend`, `:before`, `:after`, `:replace`)
- `:use_view_transitions` - Enable View Transitions API
- `:event_id` - Event ID for client tracking
- `:retry` - Retry duration in milliseconds

### Datastar.Script

Execute JavaScript and manage browser state:

- `execute(sse, script, opts)` - Execute JavaScript code
- `executef(sse, format, args, opts)` - Execute with formatting
- `console_log(sse, message, opts)` - Log to browser console
- `console_error(sse, message, opts)` - Log error to console
- `redirect(sse, url, opts)` - Navigate to URL
- `redirectf(sse, format, args, opts)` - Navigate with formatting
- `replace_url(sse, url, opts)` - Update URL without navigation
- `replace_url_querystring(sse, qs, opts)` - Update query string
- `dispatch_custom_event(sse, event, detail, opts)` - Dispatch DOM event
- `prefetch(sse, urls, opts)` - Prefetch URLs using Speculation Rules API

**Options:**
- `:auto_remove` - Remove script element after execution (default: true)
- `:attributes` - Additional script element attributes
- `:event_id` - Event ID for client tracking
- `:retry` - Retry duration in milliseconds

## Complete Example

Here's a complete example of a Phoenix LiveView-style counter:

```elixir
defmodule MyAppWeb.CounterController do
  use MyAppWeb, :controller
  alias Datastar.{SSE, Elements, Signals, Script}

  def increment(conn, _params) do
    # Read current count from client
    signals = Signals.read(conn)
    current_count = signals["count"] || 0
    new_count = current_count + 1

    # Stream updates back
    conn
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)
    |> SSE.new()
    |> Signals.patch(%{count: new_count})
    |> Elements.patch(
      "<div>Count: #{new_count}</div>",
      selector: "#counter"
    )
    |> Script.console_log("Count updated to #{new_count}")
  end

  def reset(conn, _params) do
    conn
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)
    |> SSE.new()
    |> Signals.patch(%{count: 0})
    |> Elements.patch("<div>Count: 0</div>", selector: "#counter")
    |> Script.dispatch_custom_event("counter-reset", %{})
  end
end
```

## Comparison with Go SDK

This Elixir SDK closely follows the design of the [Go implementation](https://github.com/starfederation/datastar-go), with idiomatic Elixir adaptations:

- **Functional API**: Methods return updated SSE structs for easy piping
- **Pattern Matching**: Leverage Elixir's pattern matching for cleaner code
- **Keyword Options**: Use keyword lists instead of functional options
- **Error Handling**: Provide both safe (`{:ok, result}`) and bang (`result!`) variants

## Requirements

- Elixir 1.14 or later
- Plug (optional, but recommended for web applications)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Resources

- [Datastar Official Documentation](https://data-star.dev)
- [Datastar Go SDK](https://github.com/starfederation/datastar-go)
- [Server-Sent Events Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)

## Acknowledgments

This SDK is modeled after the excellent [Datastar Go SDK](https://github.com/starfederation/datastar-go) by the Star Federation team.