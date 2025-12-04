defmodule Datastar.Examples.RocketTodoListExample do
  @moduledoc """
  Example implementation of a todo list using Datastar Pro with Rocket templates.

  This example demonstrates:
  - Reactive list rendering with data-for
  - Client-side template rendering
  - Simplified server-side logic (no HTML generation)
  - Component-scoped signals with $$

  ## Usage in a Phoenix Controller

      defmodule MyAppWeb.RocketTodoController do
        use MyAppWeb, :controller

        def add(conn, %{"text" => text}) do
          Datastar.Examples.RocketTodoListExample.add_todo(conn, text)
        end

        def remove(conn, %{"id" => id}) do
          Datastar.Examples.RocketTodoListExample.remove_todo(conn, id)
        end

        def toggle(conn, %{"id" => id}) do
          Datastar.Examples.RocketTodoListExample.toggle_todo(conn, id)
        end
      end

  ## Frontend HTML (Requires Datastar Pro with Rocket)

      <!-- Define the Rocket component -->
      <template data-rocket:todo-list data-props:todos="array|=[]">
        <script>
          $$newTodoText = ''
        </script>

        <h1>Todo List (Rocket Edition)</h1>

        <div class="add-todo">
          <input
            type="text"
            data-bind:newTodoText
            placeholder="Enter new todo"
          />
          <button data-on:click="@post('/todos/add', {text: $$newTodoText}); $$newTodoText = ''">
            Add Todo
          </button>
        </div>

        <template data-if="$$todos.length > 0">
          <ul id="todo-list">
            <template data-for="todo in $$todos" data-key="todo.id">
              <li data-class:completed="todo.completed">
                <input
                  type="checkbox"
                  data-bind:checked="todo.completed"
                  data-on:change="@post('/todos/' + todo.id + '/toggle')"
                />
                <span data-text="todo.text"></span>
                <button data-on:click="@delete('/todos/' + todo.id)">Delete</button>
              </li>
            </template>
          </ul>
        </template>

        <template data-else>
          <p class="empty-message">No todos yet. Add one above!</p>
        </template>

        <div class="todo-stats">
          <span data-text="$$todos.length + ' total'"></span>
          <span data-text="$$todos.filter(t => t.completed).length + ' completed'"></span>
        </div>
      </template>

      <!-- Use the component -->
      <todo-list></todo-list>

      <script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/datastar@v1.0.0-beta.5/bundles/datastar.js"></script>

  """

  alias Datastar.{SSE, Signals, Script}

  @doc """
  Adds a new todo item.

  With Rocket, we only need to update the signal - the template handles rendering.
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

    # Just update the signal - Rocket's data-for handles the rest!
    conn
    |> Plug.Conn.put_resp_content_type("text/event-stream")
    |> Plug.Conn.send_chunked(200)
    |> SSE.new()
    |> Signals.patch(%{todos: updated_todos})
    |> Script.console_log("Added todo: #{text}")
    |> Script.dispatch_custom_event("todo:added", %{id: id, text: text})

    conn
  end

  @doc """
  Removes a todo item.

  Again, just update the signal - the template reactively updates.
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
    |> Script.console_log("Removed todo: #{id}")
    |> Script.dispatch_custom_event("todo:removed", %{id: id})

    conn
  end

  @doc """
  Toggles a todo item's completed status.

  No DOM manipulation needed - just update the data!
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

    conn
    |> Plug.Conn.put_resp_content_type("text/event-stream")
    |> Plug.Conn.send_chunked(200)
    |> SSE.new()
    |> Signals.patch(%{todos: updated_todos})
    |> Script.console_log("Toggled todo: #{id}")
    |> Script.dispatch_custom_event("todo:toggled", %{id: id, completed: is_completed})

    conn
  end
end
