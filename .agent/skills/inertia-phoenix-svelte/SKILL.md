---
name: inertia-phoenix-svelte
description: Use when building, refactoring, or testing full-stack applications with Phoenix (Elixir) and Svelte (or Svelte 5) using Inertia.js. Triggers on: Inertia.js, inertia-phoenix, render_inertia, assign_prop, assign_errors, @inertiajs/svelte, Svelte page components, deferred props, merge props, once props, or full-stack Phoenix Svelte routing and forms.
---

# Inertia.js with Phoenix & Svelte

## Overview

Inertia.js bridges Phoenix backend controllers and Svelte frontend components into a single monolith without creating a REST or GraphQL API. Phoenix handles server-side routing, database queries, and authorization, while Svelte renders the client UI with seamless SPA page transitions.

## When to Use

- Building or modifying Phoenix controller actions that render frontend pages using `render_inertia/2,3`.
- Wiring Svelte (especially Svelte 5 runes and snippets) components to Phoenix controllers via `@inertiajs/svelte`.
- Implementing async or progressive data loading with Inertia 2.x deferred props, merge props, or once props.
- Handling form submissions, Ecto changeset validation errors, redirects, and flash messages across the stack.
- Writing controller and integration tests for Inertia endpoints.

### When NOT to Use

- When building with Phoenix LiveView instead of Inertia.
- When creating pure REST/JSON APIs for third-party consumers.
- When working with React or Vue frontends (adapt concepts, but component bindings differ).

---

## Quick Reference

| Feature | Phoenix (Backend) | Svelte 5 (Frontend) | Reference |
|---|---|---|---|
| **Render Page** | `render_inertia(conn, "pages/name", props)` | Page component in `assets/js/pages/` | [controller-helpers.md](references/controller-helpers.md) |
| **Assign Prop** | `assign_prop(conn, :key, val)` | `let { key }: Props = $props();` | [svelte-patterns.md](references/svelte-patterns.md) |
| **Deferred Prop** | `assign_prop(:kpis, inertia_defer(fn -> ... end))` | `<Deferred data="kpis">` with `{#snippet fallback()}` | [svelte-patterns.md](references/svelte-patterns.md) |
| **Merge Props** | `assign_prop(:list, inertia_merge(items))` | Append items on partial reload | [controller-helpers.md](references/controller-helpers.md) |
| **Once Prop (Cache)**| `assign_prop(:roles, inertia_once(fn -> ... end, until: 3600))` | Automatic client cache | [controller-helpers.md](references/controller-helpers.md) |
| **Form Errors** | `assign_errors(conn, changeset)` | `const form = useForm({...}); $form.errors` | [svelte-patterns.md](references/svelte-patterns.md) |
| **Shared Data** | `assign_prop(conn, :user, user)` in pipeline plug | `$page.props.user` or `$derived($page.props.user)` | [svelte-patterns.md](references/svelte-patterns.md) |
| **Flash Messages**| `put_flash(conn, :info, "Saved")` | `$page.props.flash?.info` | [svelte-patterns.md](references/svelte-patterns.md) |
| **Testing** | `inertia_component(conn)`, `inertia_props(conn)` | `Inertia.Testing` | [testing.md](references/testing.md) |

---

## Phoenix Configuration & Setup

### 1. `config/config.exs`
```elixir
config :inertia,
  endpoint: MyAppWeb.Endpoint,
  static_paths: ["/assets/app.js"],
  default_version: "1",
  camelize_props: true, # Converts :first_name to firstName in JS
  history: [encrypt: false]
```

### 2. Helpers & Router Pipeline
```elixir
# lib/my_app_web.ex
def controller do
  quote do
    use Phoenix.Controller, namespace: MyAppWeb
    import Inertia.Controller # <-- Adds render_inertia, assign_prop, assign_errors
  end
end

def html do
  quote do
    use Phoenix.Component
    import Inertia.HTML # <-- Adds <.inertia_title>, <.inertia_head>
  end
end

# lib/my_app_web/router.ex
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :protect_from_forgery
  plug :put_secure_browser_headers
  plug Inertia.Plug # <-- REQUIRED: intercepts Inertia requests
end
```

### 3. Root Layout (`root.html.heex`)
```heex
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <.inertia_title>{@page_title}</.inertia_title>
    <.inertia_head content={@inertia_head} />
    <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
    <script type="module" defer phx-track-static src={~p"/assets/app.js"}></script>
  </head>
  <body class="bg-background text-foreground antialiased">
    {@inner_content}
  </body>
</html>
```

---

## Client-Side Svelte 5 Setup

### 1. Application Entrypoint (`assets/js/app.ts`)
```typescript
import "../css/app.css";
import { createInertiaApp } from "@inertiajs/svelte";
import { mount } from "svelte";
import axios from "axios";
import DefaultLayout from "$layouts/default.svelte";

// CRITICAL: Phoenix CSRF header mapping
axios.defaults.xsrfHeaderName = "x-csrf-token";

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob("./pages/**/*.svelte", { eager: true });
    const page = pages[`./pages/${name}.svelte`] as any;
    return {
      default: page.default,
      layout: page.layout || DefaultLayout,
    };
  },
  setup({ el, App, props }) {
    mount(App, { target: el, props });
  },
  progress: { delay: 250, color: "#000" },
});
```

### 2. Persistent Layout (`assets/js/layouts/default.svelte`)
```svelte
<script lang="ts">
  import type { Snippet } from "svelte";
  import { Link, page } from "@inertiajs/svelte";

  type Props = { children: Snippet };
  let { children }: Props = $props();
  let flash = $derived($page.props.flash);
</script>

<header>
  <nav><Link href="/dashboard">Dashboard</Link></nav>
  {#if flash?.info}<div class="alert">{flash.info}</div>{/if}
</header>
<main>
  {@render children()}
</main>
```

---

## Core Patterns

### Pattern 1: Controller to Svelte Page Component

**Phoenix Controller (`lib/my_app_web/controllers/project_controller.ex`):**
```elixir
def show(conn, %{"id" => id}) do
  project = Projects.get_project!(id)

  conn
  |> assign_prop(:project, project)
  |> assign_prop(:member_count, 12)
  |> render_inertia("projects/show")
end
```

**Svelte 5 Page Component (`assets/js/pages/projects/show.svelte`):**
```svelte
<script lang="ts">
  import type { Project } from "$types";

  type Props = {
    project: Project;
    memberCount: number; # camelCase when camelize_props: true
  };

  let { project, memberCount }: Props = $props();
</script>

<h1>{project.name}</h1>
<p>Members: {memberCount}</p>
```

---

### Pattern 2: Deferred Props & Svelte Snippets

When data is slow to calculate, defer it to keep initial page render instant.

**Phoenix Controller:**
```elixir
conn
|> assign_prop(:project, project)
|> assign_prop(
  :kpis,
  inertia_defer(fn -> Metrics.calculate_kpis(project.id) end)
)
|> render_inertia("projects/dashboard")
```

**Svelte 5 Component:**
```svelte
<script lang="ts">
  import { Deferred } from "@inertiajs/svelte";
  import { Skeleton } from "$lib/components/ui/skeleton";

  type Props = {
    project: any;
    kpis?: { totalEvents: number; successRate: number };
  };

  let { project, kpis }: Props = $props();
</script>

<h1>{project.name}</h1>

<Deferred data="kpis">
  {#snippet fallback()}
    <Skeleton class="h-8 w-32" />
  {/snippet}

  {#if kpis}
    <div>Total: {kpis.totalEvents} ({kpis.successRate}%)</div>
  {/if}
</Deferred>
```

---

### Pattern 3: Forms, Validations & Redirects

**Phoenix Controller:**
```elixir
def create(conn, %{"user" => user_params}) do
  case Accounts.create_user(user_params) do
    {:ok, user} ->
      conn
      |> put_flash(:info, "User created successfully")
      |> redirect(to: ~p"/users/#{user.id}")

    {:error, %Ecto.Changeset{} = changeset} ->
      conn
      |> assign_errors(changeset) # Flattens errors and persists across redirect
      |> redirect(to: ~p"/users/new")
  end
end
```

**Svelte 5 Component (`assets/js/pages/users/new.svelte`):**
```svelte
<script lang="ts">
  import { useForm } from "@inertiajs/svelte";

  const form = useForm({
    email: "",
    name: "",
  });

  function submit(e: SubmitEvent) {
    e.preventDefault();
    $form.post("/users", {
      preserveScroll: true,
    });
  }
</script>

<form onsubmit={submit}>
  <div>
    <input bind:value={$form.name} placeholder="Name" />
    {#if $form.errors.name}<span class="error">{$form.errors.name}</span>{/if}
  </div>

  <div>
    <input bind:value={$form.email} placeholder="Email" />
    {#if $form.errors.email}<span class="error">{$form.errors.email}</span>{/if}
  </div>

  <button type="submit" disabled={$form.processing}>Submit</button>
</form>
```

---

## Common Mistakes & Troubleshooting

| Mistake | Symptom | Fix |
|---|---|---|
| **Missing `axios` CSRF header** | `403 Forbidden` / `Invalid CSRF token` on POST/PUT/DELETE | Add `axios.defaults.xsrfHeaderName = "x-csrf-token"` in `app.ts` |
| **Missing `Inertia.Plug`** | Inertia requests return full HTML layouts instead of JSON | Add `plug Inertia.Plug` in `:browser` router pipeline |
| **Prop casing mismatch** | Prop is `undefined` in Svelte | When `camelize_props: true`, Elixir `:user_id` becomes `userId` in Svelte `$props()` |
| **Passing raw Ecto structs** | `Jason.EncodeError: cannot encode struct` | Preload associations and pass through a serializer or `Map.take` before `assign_prop` |
| **Missing root components** | Page title or head metadata does not update on navigation | Use `<.inertia_title>` and `<.inertia_head>` in `root.html.heex` |
| **Svelte 4 event syntax** | Event handler does not fire or compiles with warning | Use Svelte 5 `onclick` and `onsubmit`, never `on:click` or `on:submit` |
| **Errors lost on redirect** | Form errors disappear after redirect | Always use `assign_errors(conn, changeset)` before `redirect(to: ...)` |

---

## Detailed References

For comprehensive references, consult the supporting documentation:
- [Phoenix Controller Helpers](references/controller-helpers.md) (`assign_prop`, `inertia_defer`, `inertia_merge`, `inertia_once`, `inertia_scroll`, `assign_errors`)
- [Svelte 5 Frontend Patterns](references/svelte-patterns.md) (`createInertiaApp`, persistent layouts, `useForm`, `router`, `<Deferred>`, `usePoll`)
- [Controller & Integration Testing](references/testing.md) (`inertia_component`, `inertia_props`, `inertia_errors`)
