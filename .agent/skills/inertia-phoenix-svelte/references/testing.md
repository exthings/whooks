# Testing Phoenix Inertia Controllers

The `Inertia.Testing` module provides assertion helpers for controller responses.

## Setup in `ConnCase`

Import `Inertia.Testing` into your `ConnCase`:

```elixir
# test/support/conn_case.ex
defmodule MyAppWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use MyAppWeb, :verified_routes
      import Plug.Conn
      import Phoenix.ConnTest
      import MyAppWeb.ConnCase
      import Inertia.Testing # <-- Add here
    end
  end
  # ...
end
```

---

## Test Helpers

### `inertia_component(conn)`
Returns the component string passed to `render_inertia/3`.

```elixir
assert inertia_component(conn) == "Dashboard"
```

### `inertia_props(conn)`
Returns the decoded map of props sent in the response.

```elixir
props = inertia_props(conn)
assert %{user: %{id: 1, email: "test@example.com"}} = props
```

### `inertia_errors(conn)`
Returns the map of validation errors assigned via `assign_errors/2`.

```elixir
assert inertia_errors(conn) == %{"name" => "can't be blank"}
```

---

## Example Test Cases

### 1. Testing Page Rendering & Props

```elixir
defmodule MyAppWeb.ProjectControllerTest do
  use MyAppWeb.ConnCase, async: true

  describe "GET /projects/:id" do
    test "renders project details with serialized props", %{conn: conn} do
      project = insert(:project, name: "Alpha")

      conn = get(conn, ~p"/projects/#{project.id}")

      assert inertia_component(conn) == "projects/show"
      
      props = inertia_props(conn)
      assert props.project.name == "Alpha"
      assert props.project.id == project.id
    end
  end
end
```

### 2. Testing Form Validations & Redirects

```elixir
defmodule MyAppWeb.UserControllerTest do
  use MyAppWeb.ConnCase, async: true

  describe "POST /users" do
    test "redirects with validation errors on invalid params", %{conn: conn} do
      conn = post(conn, ~p"/users", %{"user" => %{"email" => ""}})

      assert redirected_to(conn) == ~p"/users/new"
      assert inertia_errors(conn) == %{"email" => "can't be blank"}
    end

    test "redirects with flash on success", %{conn: conn} do
      conn = post(conn, ~p"/users", %{"user" => %{"email" => "dev@example.com", "name" => "Dev"}})

      assert redirected_to(conn) =~ ~p"/users/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "User created"
    end
  end
end
```

### 3. Testing Partial Reloads

Simulate an Inertia request and verify partial prop filtering:

```elixir
test "evaluates lazy props when requested via partial reload", %{conn: conn} do
  conn =
    conn
    |> put_req_header("x-inertia", "true")
    |> put_req_header("x-inertia-partial-component", "Dashboard")
    |> put_req_header("x-inertia-partial-data", "heavy_stats")
    |> get(~p"/dashboard")

  props = inertia_props(conn)
  assert Map.has_key?(props, :heavy_stats)
  refute Map.has_key?(props, :other_prop)
end
```
