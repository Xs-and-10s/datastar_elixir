# Datastar for Elixir

An Elixir SDK for the [Datastar](https://data-star.dev) web framework, modeled after the [Go implementation](https://github.com/starfederation/datastar-go).

Datastar enables real-time, server-driven UI updates using Server-Sent Events (SSE). This library provides a clean, idiomatic Elixir interface for streaming dynamic updates to your web applications.

## Features

- **Server-Sent Events (SSE)** - Stream real-time updates to connected clients
- **Signal Management** - Read and patch client-side reactive state
- **DOM Manipulation** - Update, append, prepend, and remove HTML elements
- **JavaScript Execution** - Execute scripts, log to console, and dispatch events
- **Navigation Control** - Redirect and manipulate browser history
- **Type-Safe** - Leverages Elixir's pattern matching and type specs

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
  alias Datastar.{SSE, Elements}

  def stream(conn, _params) do
    conn
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)
    |> SSE.new()
    |> Elements.patch(
      "<div id='content'>Hello, Datastar!</div>",
      selector: "#content"
    )

    conn
  end
end
```

### Reading Signals

Signals represent client-side state that can be synchronized with the server:

```elixir
def handle_request(conn, _params) do
  # Read signals from the request
  signals = Signals.read(conn)
  count = Map.get(signals, "count", 0)
  new_count = count + 1

  # Update the client state
  conn
  |> put_resp_content_type("text/event-stream")
  |> send_chunked(200)
  |> SSE.new()
  |> Signals.patch(%{count: new_count})

  conn
end
```

### Patching Elements

Update DOM elements with various merge strategies:

```elixir
sse
# Replace entire element (outer HTML)
|> Elements.patch("<div id='box'>New content</div>", selector: "#box")

# Replace inner HTML only
|> Elements.patch("<p id='container'>Inner content</p>", selector: "#container", mode: :inner)

# Append to element
|> Elements.patch("<li>New item</li>", selector: "ul", mode: :append)

# Prepend to element
|> Elements.patch("<li>First item</li>", selector: "ul", mode: :prepend)

# Insert before element
|> Elements.patch("<div>Before target</div>", selector: "#target", mode: :before)

# Insert after element
|> Elements.patch("<div>After target</div>", selector: "#target", mode: :after)
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
|> Script.dispatch_custom_event("user:updated", %{id: 123, name: "Alice"})

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
- `patch_outer(sse, html, opts)` - Replace outer HTML of element
- `patch_inner(sse, html, opts)` - Replace inner HTML of element
- `patch_prepend(sse, html, opts)` - Prepend HTML to element's children
- `patch_append(sse, html, opts)` - Append HTML to element's children
- `patch_before(sse, html, opts)` - Insert HTML before element
- `patch_after(sse, html, opts)` - Insert HTML after element
- `patch_replace(sse, html, opts)` - Replace element entirely

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

Here's a complete example of a reactive counter (see `examples/counter_example.ex` for full code):

**Backend (Phoenix Controller):**

```elixir
defmodule MyAppWeb.CounterController do
  use MyAppWeb, :controller
  alias Datastar.{SSE, Signals, Script}

  def increment(conn, _params) do
    # Read current count from client
    signals = Signals.read(conn)
    current_count = Map.get(signals, "count", 0)
    new_count = current_count + 1

    # Stream updates back
    conn
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)
    |> SSE.new()
    |> Signals.patch(%{count: new_count})
    |> Script.console_log("Count updated to #{new_count}")
    |> Script.dispatch_custom_event("counter:changed", %{value: new_count, action: "increment"})

    conn
  end
end
```

**Frontend HTML:**

```html
<div id="counter-app" data-signals="{count: 0}">
  <h1>Counter</h1>
  <div id="counter-display">Count: <span data-text="$count"></span></div>
  <button data-on:click="@get('/counter/increment')">Increment</button>
</div>

<script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/datastar@v1.0.0-beta.5/bundles/datastar.js"></script>
```

The server only needs to update the signal - Datastar's `data-text` binding automatically updates the UI!

## Signals.patch vs. Elements.patch

| Method | Description |
| --- | --- |
| `Signals.patch` | Updates the state of a signal |
| `Elements.patch` | Updates the HTML content of an element |

"Will the client need this data?"
- No -> Use only `Elements.patch` for updating HTML content.
- Yes -> "Can I use Rocket?"
  - Yes -> Use only `Signals.patch` for updating state and let your reactive component handle the UI updates.
  - No -> Use `Signals.patch` for state updates and `Elements.patch` for UI updates.

### Examples where you'd need both `Signals.patch` and `Elements.patch`

See `examples/todo_list_example.ex`

### Examples where you'd only want to use `Signals.patch`

See `examples/rocket_todo_list_example.ex`

### Examples where you'd need only `Elements.patch`

#### 1. Ephemeral UI Updates (No State)
When you want to show temporary feedback that doesn't represent application state:
```elixir
# Flash message that appears and disappears
conn
|> SSE.new()
|> Elements.patch(
  "<div class='notification'>Saved successfully!</div>",
  selector: "#notifications",
  mode: :append
)
# No signal needed - it's just a temporary message
```

#### 2. Server-Rendered Content Without Client State
When the server is the single source of truth and client doesn't need to track the data:
```elixir
# Rendering a complex dashboard widget
conn
|> SSE.new()
|> Elements.patch(
  render_dashboard_widget(data),
  selector: "#dashboard"
)
# Client doesn't need the underlying data in signals, just the rendered HTML
```

#### 3. Static Content Injection
When you're adding content that won't be manipulated by client-side code:
``` elixir
# Appending a log entry
conn
|> SSE.new()
|> Elements.patch(
  "<div class='log-entry'>#{timestamp}: #{message}</div>",
  selector: "#activity-log",
  mode: :append
)
# No need for client to have log data in signals
```

#### 4. Performance Optimization for Large Lists
When you have a list so large that keeping it in signals would be wasteful:
```elixir
# Infinite scroll - just append, don't track all items
conn
|> SSE.new()
|> Elements.patch(
  render_next_page_items(items),
  selector: "#items-list",
  mode: :append
)
# Signals would grow indefinitely, but DOM can be pruned
```

#### 5. Non-Reactive Components
When you're updating parts of the UI that don't need reactivity:
```elixir
# Update a static timestamp
conn
|> SSE.new()
|> Elements.patch(
  "<span>Last updated: #{DateTime.utc_now()}</span>",
  selector: "#last-updated"
)
# No reactive bindings needed
```

#### 6. Complex HTML That's Hard to Recreate from Signals
When the HTML structure is too complex to feasibly render from signal data alone:
```elixir
# Rich formatted content with nested structure
conn
|> SSE.new()
|> Elements.patch(
  render_markdown_with_syntax_highlighting(content),
  selector: "#article-body"
)
# Signals would be complex, HTML is easier
```

## Requirements

- Elixir 1.14 or later
- Plug (optional, but recommended for web applications)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Resources

- [Datastar Official Documentation](https://data-star.dev)
- [Server-Sent Events Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)

## Acknowledgments

This SDK is modeled after the excellent [Datastar Go SDK](https://github.com/starfederation/datastar-go) by the Star Federation team.
