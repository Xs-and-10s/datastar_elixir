defmodule Datastar.Signals do
  @moduledoc """
  Functions for reading and patching Datastar signals.

  Signals represent client-side reactive state that can be synchronized
  between the server and browser.

  ## Reading Signals

  Signals can be read from GET requests (query parameters) or from the
  request body for other HTTP methods:

      # Read signals into a map
      signals = Datastar.Signals.read(conn)

      # Read signals into a struct
      {:ok, user_signals} = Datastar.Signals.read_as(conn, UserSignals)

  ## Patching Signals

  Send signal updates to the client:

      sse
      |> Datastar.Signals.patch(%{count: 42, message: "Hello"})

      # Only patch if the signal doesn't exist on the client
      sse
      |> Datastar.Signals.patch(%{count: 42}, only_if_missing: true)

  """

  alias Datastar.{SSE, Constants}

  @datastar_key "datastar"

  @doc """
  Reads signals from a Plug connection.

  For GET requests, reads from query parameters under the "datastar" key.
  For other methods, reads from the JSON request body.

  Returns a map of signals or an empty map if no signals are present.

  ## Example

      signals = Datastar.Signals.read(conn)
      # => %{"count" => 10, "message" => "Hello"}

  """
  @spec read(Plug.Conn.t()) :: map()
  def read(%Plug.Conn{method: "GET", query_params: params}) do
    case Map.get(params, @datastar_key) do
      nil -> %{}
      json_string -> decode_signals(json_string)
    end
  end

  def read(%Plug.Conn{} = conn) do
    case conn.body_params do
      %Plug.Conn.Unfetched{} ->
        # Body hasn't been read yet
        {:ok, body, _conn} = Plug.Conn.read_body(conn)
        decode_signals(body)

      body_params when is_map(body_params) ->
        body_params

      _ ->
        %{}
    end
  end

  @doc """
  Reads signals from a connection and decodes them into a struct.

  ## Example

      defmodule UserSignals do
        defstruct [:name, :email, :count]
      end

      {:ok, signals} = Datastar.Signals.read_as(conn, UserSignals)

  """
  @spec read_as(Plug.Conn.t(), module()) :: {:ok, struct()} | {:error, term()}
  def read_as(conn, module) do
    signals = read(conn)

    try do
      struct = struct(module, map_to_keyword(signals))
      {:ok, struct}
    rescue
      e -> {:error, e}
    end
  end

  @doc """
  Patches signals on the client by sending an SSE event.

  ## Options

  - `:only_if_missing` - Only patch signals that don't exist on the client (default: false)
  - `:event_id` - Event ID for client tracking
  - `:retry` - Retry duration in milliseconds

  ## Example

      sse
      |> Datastar.Signals.patch(%{count: 42})
      |> Datastar.Signals.patch(%{message: "Hello"}, only_if_missing: true)

  """
  @spec patch(SSE.t(), map(), keyword()) :: SSE.t()
  def patch(sse, signals, opts \\ []) when is_map(signals) do
    json = Jason.encode!(signals)
    patch_raw(sse, json, opts)
  end

  @doc """
  Patches signals using a raw JSON string.

  ## Example

      sse
      |> Datastar.Signals.patch_raw(~s({"count": 42}))

  """
  @spec patch_raw(SSE.t(), String.t(), keyword()) :: SSE.t()
  def patch_raw(sse, json, opts \\ []) when is_binary(json) do
    only_if_missing = Keyword.get(opts, :only_if_missing, Constants.default_patch_signals_only_if_missing())

    data_lines =
      []
      |> maybe_add_only_if_missing(only_if_missing)
      |> add_signals_data(json)

    event_opts = [
      event_id: opts[:event_id],
      retry: opts[:retry]
    ]
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)

    SSE.send_event!(sse, Constants.event_type_patch_signals(), data_lines, event_opts)
  end

  @doc """
  Patches signals only if they don't exist on the client.

  Convenience function equivalent to calling `patch/3` with `only_if_missing: true`.

  ## Example

      sse
      |> Datastar.Signals.patch_if_missing(%{count: 42})

  """
  @spec patch_if_missing(SSE.t(), map(), keyword()) :: SSE.t()
  def patch_if_missing(sse, signals, opts \\ []) do
    opts = Keyword.put(opts, :only_if_missing, true)
    patch(sse, signals, opts)
  end

  # Private helpers

  defp decode_signals(""), do: %{}
  defp decode_signals(nil), do: %{}

  defp decode_signals(json_string) when is_binary(json_string) do
    case Jason.decode(json_string) do
      {:ok, map} -> map
      {:error, _} -> %{}
    end
  end

  defp map_to_keyword(map) when is_map(map) do
    Enum.map(map, fn
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
      {k, v} when is_atom(k) -> {k, v}
    end)
  end

  defp maybe_add_only_if_missing(lines, false), do: lines
  defp maybe_add_only_if_missing(lines, true) do
    lines ++ [Constants.only_if_missing_dataline() <> "true"]
  end

  defp add_signals_data(lines, json) do
    lines ++ [Constants.signals_dataline() <> json]
  end
end
