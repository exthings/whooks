# Svelte 5 with Inertia.js Patterns & Reference

This guide covers idiomatic patterns for building Svelte 5 frontend applications powered by `@inertiajs/svelte` and Phoenix.

## Client Initialization (`app.ts`)

In Svelte 5, use `mount` from `svelte` inside `createInertiaApp`:

```typescript
// assets/js/app.ts
import "../css/app.css";
import { createInertiaApp } from "@inertiajs/svelte";
import { mount } from "svelte";
import axios from "axios";
import DefaultLayout from "$layouts/default.svelte";

// CRITICAL: Configure CSRF header for Phoenix
axios.defaults.xsrfHeaderName = "x-csrf-token";

createInertiaApp({
  resolve: (name) => {
    // Glob import all pages
    const pages = import.meta.glob("./pages/**/*.svelte", { eager: true });
    const page = pages[`./pages/${name}.svelte`] as any;
    
    // Support per-page layout override or fallback to DefaultLayout
    return {
      default: page.default,
      layout: page.layout || DefaultLayout,
    };
  },
  setup({ el, App, props }) {
    mount(App, { target: el, props });
  },
  progress: {
    delay: 250,
    color: "#4f46e5",
  },
});
```

---

## Page Components & Svelte 5 Runes

Page components receive props passed from Phoenix controllers directly via `$props()`:

```svelte
<!-- assets/js/pages/users/show.svelte -->
<script lang="ts">
  import type { User } from "$types";

  type Props = {
    user: User;
    unreadCount?: number;
  };

  // Note: if camelize_props: true in Phoenix, props are camelCased
  let { user, unreadCount = 0 }: Props = $props();
</script>

<h1>{user.name} ({user.email})</h1>
<p>Unread notifications: {unreadCount}</p>
```

---

## Persistent Layouts

### 1. Defining a Layout Component
In Svelte 5, layout components receive `children` as a `Snippet`:

```svelte
<!-- assets/js/layouts/default.svelte -->
<script lang="ts">
  import type { Snippet } from "svelte";
  import { Link, page } from "@inertiajs/svelte";

  type Props = {
    children: Snippet;
  };

  let { children }: Props = $props();
  let flash = $derived($page.props.flash);
</script>

<nav>
  <Link href="/dashboard">Dashboard</Link>
  <Link href="/profile">Profile</Link>
</nav>

{#if flash?.info}
  <div class="alert alert-info">{flash.info}</div>
{/if}

<main>
  {@render children()}
</main>
```

### 2. Overriding Layout in a Page Component
Use a module script (`<script module>`):

```svelte
<!-- assets/js/pages/auth/login.svelte -->
<script module>
  export { default as layout } from "$layouts/blank.svelte";
</script>

<script lang="ts">
  // Regular page logic here
</script>
```

---

## Handling Deferred Props (`<Deferred>`)

When Phoenix passes a prop with `inertia_defer/1`, it arrives asynchronously after initial mount. Use the `<Deferred>` component with Svelte 5 snippet syntax:

```svelte
<script lang="ts">
  import { Deferred } from "@inertiajs/svelte";
  import { Skeleton } from "$lib/components/ui/skeleton";

  type Props = {
    kpis?: { total: number; revenue: number };
  };

  let { kpis }: Props = $props();
</script>

<Deferred data="kpis">
  {#snippet fallback()}
    <div class="kpi-skeleton">
      <Skeleton class="h-8 w-24" />
      <Skeleton class="h-8 w-24" />
    </div>
  {/snippet}

  {#if kpis}
    <div class="kpi-grid">
      <div>Total: {kpis.total}</div>
      <div>Revenue: {kpis.revenue}</div>
    </div>
  {/if}
</Deferred>
```

---

## Forms & Validations (`useForm`)

The `useForm` helper manages reactive form state, errors sent from Phoenix `assign_errors(changeset)`, and submission flags:

```svelte
<script lang="ts">
  import { useForm } from "@inertiajs/svelte";

  type FormData = {
    email: string;
    name: string;
  };

  const form = useForm<FormData>({
    email: "",
    name: "",
  });

  function handleSubmit(event: SubmitEvent) {
    event.preventDefault();

    $form.post("/users", {
      preserveScroll: true,
      onSuccess: () => {
        $form.reset();
      },
    });
  }
</script>

<form onsubmit={handleSubmit}>
  <div>
    <label for="name">Name</label>
    <input id="name" type="text" bind:value={$form.name} />
    {#if $form.errors.name}
      <span class="text-red-500 text-sm">{$form.errors.name}</span>
    {/if}
  </div>

  <div>
    <label for="email">Email</label>
    <input id="email" type="email" bind:value={$form.email} />
    {#if $form.errors.email}
      <span class="text-red-500 text-sm">{$form.errors.email}</span>
    {/if}
  </div>

  <button type="submit" disabled={$form.processing}>
    {$form.processing ? "Saving..." : "Create User"}
  </button>
</form>
```

`$form` methods and properties:
- `$form.data()`: Returns current form payload.
- `$form.post(url, opts)`, `$form.put(url, opts)`, `$form.patch(url, opts)`, `$form.delete(url, opts)`
- `$form.reset(...fields)`: Resets to initial values.
- `$form.clearErrors(...fields)`: Clears errors.
- `$form.isDirty`: Boolean indicating if values changed.
- `$form.processing`: Boolean for pending request.
- `$form.errors`: Object holding field errors returned from Phoenix.

---

## Programmatic Navigation (`router`)

```typescript
import { router } from "@inertiajs/svelte";

// Full navigation with query params
router.get("/users", { page: 2, query: "alice" }, {
  preserveState: true,
  replace: true,
});

// Partial reload (only refresh specific props)
router.reload({ only: ["users", "meta"] });

// Delete action with confirmation
function deleteItem(id: string) {
  if (confirm("Delete this item?")) {
    router.delete(`/items/${id}`, {
      preserveScroll: true,
    });
  }
}
```

---

## Real-time Polling (`usePoll`)

Poll a Phoenix endpoint periodically without re-fetching all props:

```svelte
<script lang="ts">
  import { usePoll } from "@inertiajs/svelte";

  // Poll every 3 seconds for updated events and stats
  const { start, stop } = usePoll(3000, {
    only: ["events", "metrics"],
    autoStart: true,
  });
</script>
```

---

## Accessing Shared Data (`page` store)

Global shared props (e.g. current user, organization, flash notifications) are accessible via the `page` store:

```svelte
<script lang="ts">
  import { page } from "@inertiajs/svelte";

  let user = $derived($page.props.currentScope?.user);
  let orgId = $derived($page.props.organizationId);
  let currentUrl = $derived($page.url);
</script>
```
