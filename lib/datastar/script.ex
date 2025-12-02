defmodule Datastar.Script do
  @moduledoc """
  Functions for executing JavaScript and managing browser state.

  This module provides utilities for:
  - Executing arbitrary JavaScript code
  - Console logging
  - Browser navigation and URL manipulation
  - Custom event dispatching
  - Resource prefetching

  ## Examples

      # Execute JavaScript
      sse |> Datastar.Script.execute("alert('Hello!')")

      # Console logging
      sse |> Datastar.Script.console_log("Debug message")

      # Redirect
      sse |> Datastar.Script.redirect("/dashboard")

      # Dispatch custom event
      sse |> Datastar.Script.dispatch_custom_event("my-event", %{detail: "data"})

  """

  alias Datastar.{SSE, Elements}

  @doc """
  Executes JavaScript code in the browser.

  The script is wrapped in a `<script>` element and executed immediately.

  ## Options

  - `:auto_remove` - Remove script element after execution (default: true)
  - `:attributes` - Map of additional attributes for the script element
  - `:event_id` - Event ID for client tracking
  - `:retry` - Retry duration in milliseconds

  ## Example

      sse
      |> execute("console.log('Hello from server!')")
      |> execute("document.title = 'Updated'", auto_remove: false)

  """
  @spec execute(SSE.t(), String.t(), keyword()) :: SSE.t()
  def execute(sse, script, opts \\ []) when is_binary(script) do
    auto_remove = Keyword.get(opts, :auto_remove, true)
    attributes = Keyword.get(opts, :attributes, %{})

    # Build script element
    attrs_string = build_attributes(attributes)

    script_content = if auto_remove do
      """
      #{script}
      document.currentScript.remove();
      """
    else
      script
    end

    html = "<script#{attrs_string}>#{escape_script(script_content)}</script>"

    element_opts = [
      selector: "body",
      mode: :append,
      event_id: opts[:event_id],
      retry: opts[:retry]
    ]

    Elements.patch(sse, html, element_opts)
  end

  @doc """
  Executes JavaScript with string interpolation.

  ## Example

      sse |> executef("alert('%s')", ["Hello, World!"])

  """
  @spec executef(SSE.t(), String.t(), list(), keyword()) :: SSE.t()
  def executef(sse, format, args, opts \\ []) do
    script = :io_lib.format(to_charlist(format), args) |> to_string()
    execute(sse, script, opts)
  end

  @doc """
  Logs a message to the browser console.

  ## Example

      sse
      |> console_log("User logged in")
      |> console_log("Count: %{count}", count: 42)

  """
  @spec console_log(SSE.t(), String.t(), keyword()) :: SSE.t()
  def console_log(sse, message, opts \\ []) when is_binary(message) do
    safe_message = Jason.encode!(message)
    execute(sse, "console.log(#{safe_message})", opts)
  end

  @doc """
  Logs an error to the browser console.

  ## Example

      sse |> console_error("Something went wrong!")

  """
  @spec console_error(SSE.t(), String.t(), keyword()) :: SSE.t()
  def console_error(sse, message, opts \\ []) when is_binary(message) do
    safe_message = Jason.encode!(message)
    execute(sse, "console.error(#{safe_message})", opts)
  end

  @doc """
  Redirects the browser to a new URL.

  Uses `setTimeout` to ensure proper event processing before navigation.

  ## Example

      sse
      |> redirect("/dashboard")
      |> redirect("https://example.com")

  """
  @spec redirect(SSE.t(), String.t(), keyword()) :: SSE.t()
  def redirect(sse, url, opts \\ []) when is_binary(url) do
    safe_url = Jason.encode!(url)
    script = "setTimeout(() => window.location.href = #{safe_url}, 0)"
    execute(sse, script, opts)
  end

  @doc """
  Redirects with string interpolation.

  ## Example

      sse |> redirectf("/users/%s/profile", [user_id])

  """
  @spec redirectf(SSE.t(), String.t(), list(), keyword()) :: SSE.t()
  def redirectf(sse, format, args, opts \\ []) do
    url = :io_lib.format(to_charlist(format), args) |> to_string()
    redirect(sse, url, opts)
  end

  @doc """
  Replaces the current URL without navigation using history.replaceState.

  ## Example

      sse |> replace_url("/new-path")

  """
  @spec replace_url(SSE.t(), String.t(), keyword()) :: SSE.t()
  def replace_url(sse, url, opts \\ []) when is_binary(url) do
    safe_url = Jason.encode!(url)
    script = "history.replaceState({}, '', #{safe_url})"
    execute(sse, script, opts)
  end

  @doc """
  Updates the URL query string without navigation.

  ## Example

      sse |> replace_url_querystring("?page=2&sort=name")

  """
  @spec replace_url_querystring(SSE.t(), String.t(), keyword()) :: SSE.t()
  def replace_url_querystring(sse, querystring, opts \\ []) when is_binary(querystring) do
    script = """
    const url = new URL(window.location);
    url.search = #{Jason.encode!(querystring)};
    history.replaceState({}, '', url);
    """
    execute(sse, script, opts)
  end

  @doc """
  Dispatches a custom DOM event.

  ## Example

      sse
      |> dispatch_custom_event("user-updated", %{id: 123, name: "Alice"})
      |> dispatch_custom_event("notification", %{message: "Saved!"}, selector: "#app")

  """
  @spec dispatch_custom_event(SSE.t(), String.t(), map(), keyword()) :: SSE.t()
  def dispatch_custom_event(sse, event_name, detail \\ %{}, opts \\ []) do
    selector = Keyword.get(opts, :selector, "document")
    safe_detail = Jason.encode!(detail)

    script = """
    #{selector}.dispatchEvent(
      new CustomEvent(#{Jason.encode!(event_name)}, {
        detail: #{safe_detail},
        bubbles: true
      })
    );
    """

    execute(sse, script, opts)
  end

  @doc """
  Prefetches URLs using the Speculation Rules API.

  ## Example

      sse |> prefetch(["/dashboard", "/profile"])

  """
  @spec prefetch(SSE.t(), list(String.t()), keyword()) :: SSE.t()
  def prefetch(sse, urls, opts \\ []) when is_list(urls) do
    speculation_rules = %{
      "prefetch" => [
        %{
          "urls" => urls
        }
      ]
    }

    json = Jason.encode!(speculation_rules)
    html = ~s(<script type="speculationrules">#{json}</script>)

    element_opts = [
      selector: "head",
      mode: :append,
      event_id: opts[:event_id],
      retry: opts[:retry]
    ]

    Elements.patch(sse, html, element_opts)
  end

  # Private helpers

  defp build_attributes(attrs) when map_size(attrs) == 0, do: ""
  defp build_attributes(attrs) do
    attrs
    |> Enum.map(fn {key, value} -> ~s( #{key}="#{escape_attr(value)}") end)
    |> Enum.join()
  end

  defp escape_attr(value) when is_binary(value) do
    value
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp escape_attr(value), do: to_string(value) |> escape_attr()

  defp escape_script(script) do
    String.replace(script, "</script>", "<\\/script>")
  end
end
