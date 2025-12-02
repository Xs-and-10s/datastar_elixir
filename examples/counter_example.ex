defmodule Datastar.Examples.CounterExample do
  @moduledoc """
  Example implementation of a simple counter using Datastar.

  This example demonstrates:
  - Reading signals from the client
  - Patching signals to update client state
  - Patching DOM elements
  - Console logging
  - Custom event dispatching

  ## Usage in a Phoenix Controller

      defmodule MyAppWeb.CounterController do
        use MyAppWeb, :controller

        def increment(conn, _params) do
          Datastar.Examples.CounterExample.increment(conn)
        end

        def decrement(conn, _params) do
          Datastar.Examples.CounterExample.decrement(conn)
        end

        def reset(conn, _params) do
          Datastar.Examples.CounterExample.reset(conn)
        end
      end

  ## Frontend HTML

      <div id="counter-app" data-signals="{count: 0}">
        <h1>Counter</h1>
        <div id="counter-display">Count: <span data-text="$count"></span></div>
        <button data-on:click="@get('/counter/increment')">Increment</button>
        <button data-on:click="@get('/counter/decrement')">Decrement</button>
        <button data-on:click="@get('/counter/reset')">Reset</button>
      </div>

      <script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/[email protected]/bundles/datastar.js"></script>

  """

  alias Datastar.{SSE, Elements, Signals, Script}

  @doc """
  Increments the counter value.
  """
  def increment(conn) do
    # Read current signals from the client
    signals = Signals.read(conn)
    current_count = Map.get(signals, "count", 0)
    new_count = current_count + 1

    # Send SSE updates
    conn
    |> Plug.Conn.put_resp_content_type("text/event-stream")
    |> Plug.Conn.send_chunked(200)
    |> SSE.new()
    |> Signals.patch(%{count: new_count})
    |> Elements.patch(
      "<div id='counter-display'>Count: #{new_count}</div>",
      selector: "#counter-display"
    )
    |> Script.console_log("Counter incremented to #{new_count}")
    |> Script.dispatch_custom_event("counter:changed", %{value: new_count, action: "increment"})

    conn
  end

  @doc """
  Decrements the counter value.
  """
  def decrement(conn) do
    signals = Signals.read(conn)
    current_count = Map.get(signals, "count", 0)
    new_count = current_count - 1

    conn
    |> Plug.Conn.put_resp_content_type("text/event-stream")
    |> Plug.Conn.send_chunked(200)
    |> SSE.new()
    |> Signals.patch(%{count: new_count})
    |> Elements.patch(
      "<div id='counter-display'>Count: #{new_count}</div>",
      selector: "#counter-display"
    )
    |> Script.console_log("Counter decremented to #{new_count}")
    |> Script.dispatch_custom_event("counter:changed", %{value: new_count, action: "decrement"})

    conn
  end

  @doc """
  Resets the counter to zero.
  """
  def reset(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("text/event-stream")
    |> Plug.Conn.send_chunked(200)
    |> SSE.new()
    |> Signals.patch(%{count: 0})
    |> Elements.patch(
      "<div id='counter-display'>Count: 0</div>",
      selector: "#counter-display"
    )
    |> Script.console_log("Counter reset to 0")
    |> Script.dispatch_custom_event("counter:changed", %{value: 0, action: "reset"})

    conn
  end
end
