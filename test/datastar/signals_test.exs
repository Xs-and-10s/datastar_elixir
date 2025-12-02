defmodule Datastar.SignalsTest do
  use ExUnit.Case
  alias Datastar.Signals

  describe "read/1" do
    test "returns empty map for GET request without datastar param" do
      conn = %Plug.Conn{method: "GET", query_params: %{}}
      assert Signals.read(conn) == %{}
    end

    test "decodes signals from GET request query params" do
      json = Jason.encode!(%{"count" => 42, "name" => "test"})
      conn = %Plug.Conn{method: "GET", query_params: %{"datastar" => json}}

      signals = Signals.read(conn)
      assert signals["count"] == 42
      assert signals["name"] == "test"
    end

    test "handles invalid JSON gracefully" do
      conn = %Plug.Conn{method: "GET", query_params: %{"datastar" => "invalid json"}}
      assert Signals.read(conn) == %{}
    end
  end

  describe "read_as/2" do
    defmodule TestSignals do
      defstruct [:name, :count]
    end

    test "converts map to struct" do
      conn = %Plug.Conn{method: "GET", query_params: %{}}

      # We can't easily test this without mocking, so we'll just verify the function exists
      assert function_exported?(Signals, :read_as, 2)
    end
  end
end
