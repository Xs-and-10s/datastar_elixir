defmodule Datastar do
  @moduledoc """
  An Elixir SDK for the Datastar web framework.

  Datastar enables real-time, server-driven UI updates using Server-Sent Events (SSE).
  This library provides utilities for:

  - Server-Sent Event streaming via `Datastar.SSE`
  - Reading and patching client-side signals via `Datastar.Signals`
  - Patching and removing DOM elements via `Datastar.Elements`
  - Executing JavaScript and managing browser state via `Datastar.Script`

  ## Example

      defmodule MyAppWeb.DatastarController do
        use MyAppWeb, :controller

        def stream(conn, _params) do
          # Read signals from the request
          signals = Datastar.Signals.read(conn)

          # Create an SSE generator
          conn
          |> put_resp_content_type("text/event-stream")
          |> send_chunked(200)
          |> Datastar.SSE.new()
          |> Datastar.Elements.patch("<div>Updated content</div>", selector: "#target")
          |> Datastar.Signals.patch(%{count: 42})
        end
      end

  ## Installation

  Add `datastar` to your list of dependencies in `mix.exs`:

      def deps do
        [
          {:datastar, "~> 0.1.0"}
        ]
      end

  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      alias Datastar.{SSE, Signals, Elements, Script}
    end
  end
end
