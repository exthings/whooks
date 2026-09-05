# Phoenix Inertia Controller Helpers Reference

The `Inertia.Controller` module provides functions to prepare and render Inertia responses in Phoenix controllers.

## Rendering Responses

### `render_inertia(conn, component, props \\ %{})`
Renders an Inertia response. On first visit, renders the root HTML layout containing the page JSON in a `data-page` div. On Inertia requests (`X-Inertia: true`), responds with JSON.

```elixir
def show(conn, %{"id" => id}) do
  user = Accounts.get_user!(id)

  conn
  |> assign_prop(:user, serialize(user))
  |> render_inertia("users/show", %{extra_info: "value"})
end
```

- `component`: String identifying the Svelte page component path (relative to your pages directory, e.g. `"users/show"` or `"Dashboard"`).
- `props`: Optional map of props to merge with props assigned via `assign_prop/3`.

---

## Assigning Props

### `assign_prop(conn, key, value)`
Assigns a single prop to be passed to the Svelte component.

```elixir
conn
|> assign_prop(:project, project)
|> assign_prop(:stats, fn -> compute_heavy_stats() end)
```

- When `key` is an atom and `camelize_props: true` is configured, `:project_name` becomes `projectName` on the frontend.
- `value` can be any JSON-serializable term or a function/evaluation wrapper.

### `camelize_props(conn, bool \\ true)`
Overrides the global `camelize_props` configuration for this specific connection.

```elixir
conn
|> assign_prop(:snake_case_key, value)
|> camelize_props(false)
|> render_inertia("Settings")
```

---

## Lazy & Advanced Prop Evaluation (Inertia v2)

### 1. Bare Anonymous Function (Lazy on First Visit)
Evaluated only if the prop is included in the response. On initial page load, it is evaluated. On partial reloads (`only: ["other_prop"]`), the function is skipped entirely.

```elixir
conn |> assign_prop(:expensive, fn -> calculate_expensive_data() end)
```

### 2. `inertia_optional(fun)`
Defines a prop that is **never** evaluated or included on initial page load, but **can** be requested during partial reloads.

```elixir
conn |> assign_prop(:analytics, inertia_optional(fn -> Analytics.query() end))
```

### 3. `inertia_defer(fun, group \\ nil)`
Defines a prop to be fetched asynchronously in the background by the client immediately after initial page mount.

```elixir
# Default group (fetched with other deferred props in one request)
conn |> assign_prop(:kpis, inertia_defer(fn -> compute_kpis() end))

# Custom group (fetched in parallel with its own HTTP request)
conn |> assign_prop(:heavy_report, inertia_defer(fn -> run_report() end, "reports"))
```

### 4. `inertia_merge(value)` & `inertia_deep_merge(value)`
Instructs the Inertia client to append/merge this prop into the existing prop array or map on subsequent partial reloads instead of overwriting it.

```elixir
# Shallow merge (e.g. infinite scroll items)
conn |> assign_prop(:feed, inertia_merge(new_items))

# Combine deferred + merge
conn |> assign_prop(:feed, inertia_defer(&load_more/0) |> inertia_merge())

# Deep merge for nested maps
conn |> assign_prop(:settings, inertia_deep_merge(%{theme: %{accent: "blue"}}))
```

### 5. `inertia_once(fun_or_val, opts \\ [])`
Caches the prop on the client across subsequent page visits that declare the same prop name or `as:` key.

Options:
- `:as` - Cache key (allows sharing cache across different pages/prop names)
- `:until` - Expiration time (`DateTime` or integer seconds from now)
- `:fresh` - Boolean; if true, forces client to refresh cache

```elixir
# Cache for 1 hour
conn |> assign_prop(:plans, inertia_once(fn -> Plans.list_all() end, until: 3600))

# Shared cache key between two different pages
conn |> assign_prop(:member_roles, inertia_once(fn -> Roles.list() end, as: "roles"))

# Invalidate cache when state changed
conn |> assign_prop(:plans, inertia_once(fn -> Plans.list_all() end, fresh: plans_updated?))

# Combine with defer
conn |> assign_prop(:permissions, inertia_once(inertia_defer(fn -> fetch_perms() end)))
```

### 6. `inertia_scroll(paginated_data, opts \\ [])`
Prepares paginated data for Inertia's `<InfiniteScroll>` component. Automatically configures merge props on the data key and emits `scrollProps` metadata.

Expected data shape:
```elixir
%{
  data: [...items...],
  meta: %{
    current_page: 1,
    next_page: 2,
    previous_page: nil,
    page_name: "page" # optional
  }
}
```

Options:
- `:wrapper` - Key containing items (default: `"data"`)
- `:page_name` - Query parameter name for page (default: `"page"`)
- `:metadata` - Custom function `(page -> %{...})` to extract pagination metadata

```elixir
conn
|> assign_prop(:users, inertia_scroll(paginated_users))
|> render_inertia("Users/Index")
```

---

## Form Validation Errors

### `assign_errors(conn, changeset_or_map)`
Attaches validation errors to the Inertia session. Automatically converted to a flattened string-key map (e.g. `"email" => "is invalid"`, `"user.name" => "can't be blank"`, `"items[0].name" => "too short"`).
Errors are **preserved across redirects**.

```elixir
def create(conn, %{"user" => user_params}) do
  case Accounts.create_user(user_params) do
    {:ok, user} ->
      conn
      |> put_flash(:info, "User created successfully")
      |> redirect(to: ~p"/users/#{user}")

    {:error, %Ecto.Changeset{} = changeset} ->
      conn
      |> assign_errors(changeset)
      |> redirect(to: ~p"/users/new")
  end
end
```

---

## Browser History & Security

### `encrypt_history(conn, bool \\ true)`
Instructs the client to encrypt the page history state in `window.history` for sensitive pages.

```elixir
conn
|> encrypt_history()
|> render_inertia("Billing/CardDetails")
```

### `clear_history(conn, bool \\ true)`
Instructs the client to clear existing browser history state (e.g. on logout or session invalidation).

```elixir
def delete(conn, _params) do
  conn
  |> UserAuth.log_out_user()
  |> clear_history()
  |> redirect(to: ~p"/login")
end
```
