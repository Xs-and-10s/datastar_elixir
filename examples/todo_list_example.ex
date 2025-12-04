defmodule Datastar.Examples.TodoListExample do
  @moduledoc """
  Example implementation of a todo list using Datastar.

  This example demonstrates:
  - Dynamic list management
  - Multiple DOM operations
  - Element removal
  - View transitions

  ## Usage in a Phoenix Controller

      defmodule MyAppWeb.TodoController do
        use MyAppWeb, :controller

        def add(conn, %{"text" => text}) do
          Datastar.Examples.TodoListExample.add_todo(conn, text)
        end

        def remove(conn, %{"id" => id}) do
          Datastar.Examples.TodoListExample.remove_todo(conn, id)
        end

        def toggle(conn, %{"id" => id}) do
          Datastar.Examples.TodoListExample.toggle_todo(conn, id)
        end
      end

  ## Frontend HTML

      <div id="todo-app" data-signals="{todos: [], newTodoText: ''}">
        <h1>Todo List</h1>

        <div class="add-todo">
          <input
            type="text"
            data-bind:newTodoText
            placeholder="Enter new todo"
          />
          <button data-on:click="@post('/todos/add', {text: $newTodoText}); $newTodoText = ''">
            Add Todo
          </button>
        </div>

        <ul id="todo-list">
          <!-- Todo items will be added here dynamically -->
        </ul>
      </div>

      <script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/[email protected]/bundles/datastar.js"></script>

  """

  alias Datastar.{SSE, Elements, Signals, Script}

  @doc """
  Adds a new todo item.
  """
  def add_todo(conn, text) do
    # Generate a unique ID
    id = :crypto.strong_rand_bytes(8) |> Base.encode16()

    # Read current todos
    signals = Signals.read(conn)
    todos = Map.get(signals, "todos", [])

    # Add new todo
    new_todo = %{id: id, text: text, completed: false}
    updated_todos = todos ++ [new_todo]

    # Render the new todo item
    todo_html = """
    <li id="todo-#{id}">
      <input type="checkbox" data-on:change="@post('/todos/#{id}/toggle')" />
      <span>#{text}</span>
      <button data-on:click="@delete('/todos/#{id}')">Delete</button>
    </li>
    """

    conn
    |> Plug.Conn.put_resp_content_type("text/event-stream")
    |> Plug.Conn.send_chunked(200)
    |> SSE.new()
    |> Signals.patch(%{todos: updated_todos})
    |> Elements.patch(
      todo_html,
      selector: "#todo-list",
      mode: :append,
      use_view_transitions: true
    )
    |> Script.console_log("Added todo: #{text}")
    |> Script.dispatch_custom_event("todo:added", %{id: id, text: text})

    conn
  end

  @doc """
  Removes a todo item.
  """
  def remove_todo(conn, id) do
    # Read current todos
    signals = Signals.read(conn)
    todos = Map.get(signals, "todos", [])

    # Remove the todo
    updated_todos = Enum.reject(todos, &(&1["id"] == id))

    conn
    |> Plug.Conn.put_resp_content_type("text/event-stream")
    |> Plug.Conn.send_chunked(200)
    |> SSE.new()
    |> Signals.patch(%{todos: updated_todos})
    |> Elements.remove("#todo-#{id}")
    |> Script.console_log("Removed todo: #{id}")
    |> Script.dispatch_custom_event("todo:removed", %{id: id})

    conn
  end

  @doc """
  Toggles a todo item's completed status.
  """
  def toggle_todo(conn, id) do
    # Read current todos
    signals = Signals.read(conn)
    todos = Map.get(signals, "todos", [])

    # Toggle the todo
    updated_todos =
      Enum.map(todos, fn todo ->
        if todo["id"] == id do
          Map.put(todo, "completed", !todo["completed"])
        else
          todo
        end
      end)

    # Find the toggled todo
    toggled_todo = Enum.find(updated_todos, &(&1["id"] == id))
    is_completed = toggled_todo["completed"]

    # Re-render the todo item with updated state
    todo_html = """
    <li id="todo-#{id}"#{if is_completed, do: " class=\"completed\"", else: ""}>
      <input type="checkbox"#{if is_completed, do: " checked", else: ""} data-on:change="@post('/todos/#{id}/toggle')" />
      <span>#{toggled_todo["text"]}</span>
      <button data-on:click="@delete('/todos/#{id}')">Delete</button>
    </li>
    """

    conn
    |> Plug.Conn.put_resp_content_type("text/event-stream")
    |> Plug.Conn.send_chunked(200)
    |> SSE.new()
    |> Signals.patch(%{todos: updated_todos})
    |> Elements.patch(todo_html, selector: "#todo-#{id}")
    |> Script.console_log("Toggled todo: #{id}")
    |> Script.dispatch_custom_event("todo:toggled", %{id: id, completed: is_completed})

    conn
  end
end
