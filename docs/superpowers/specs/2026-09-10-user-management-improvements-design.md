# User Management Improvements Design

## 1. Overview
This design improves the admin user management interface and access control policies in Whooks:
1. **Self-demotion protection for Root users**: A user with the `root` role cannot change their own role (preventing accidental lockout), while root users maintain administrative privileges over other accounts.
2. **Enhanced User Listing via Sidebar**: Uses the established `SidebarItem` component with a dedicated role badge to maintain visual consistency across admin views (matching Projects and Consumers).
3. **Master-Detail View Enhancements**:
   - Inline shadcn `<Select>` for rapid role updates on other users (disabled for self-root demotion with explanatory message).
   - Full user profile details organized in a structured Card layout.
   - A single scrollable flow with an Activity & Logs section containing lifecycle milestone events and an extensible container ready for future audit logs.

---

## 2. Architecture & Backend Data Flow

### 2.1 Controller & Scope Propagation
- **Module**: `WhooksWeb.UI.Admin.Settings.UsersController`
  - In `index/2` and `show/2`, pass the authenticated user into the Inertia page props:
    ```elixir
    |> assign_prop(:current_user, fn ->
      Serializer.to_map(conn.assigns.current_scope.user)
    end)
    ```
  - In `update/2`, retrieve `current_user = conn.assigns.current_scope.user` and pass it to the context update function:
    ```elixir
    with {:ok, user} <- Auth.update_user(current_user, params["id"], params) do
      conn |> redirect(to: ~p"/ui/admin/settings/users/#{user.id}")
    else
      {:error, changeset} ->
        conn
        |> assign_errors(changeset)
        |> redirect(to: ~p"/ui/admin/settings/users/#{params["id"]}")
    end
    ```

### 2.2 Auth Context & Validation Rules
- **Module**: `Whooks.Auth`
  - Define `update_user(current_user, id, attrs)`:
    - Fetches the target user by `id`.
    - If `target_user.role == :root` and `current_user.id == target_user.id`:
      - If `attrs["role"]` or `attrs[:role]` is provided and differs from `:root`, add an error to `:role`: `"root users cannot change their own role"` and return `{:error, changeset}`.
    - If `current_user.role != :root` and `(target_user.role == :root or attrs["role"] == "root" or attrs[:role] == :root)`:
      - Reject unauthorized root escalation/modification.
    - Otherwise, apply `User.update_changeset(target_user, attrs)` and `Repo.update()`.

---

## 3. Frontend Architecture

### 3.1 Sidebar Item (`assets/js/components/sidebar-item.svelte`)
- Enhance `SidebarItem` to support an optional `badge` or snippet:
  - Add optional prop: `badge?: { text: string; variant?: string }` or `roleBadge?: string`.
  - When provided, renders a role badge on the right side of the item.
  - Maintains backward compatibility with `projects-sidebar.svelte` and `consumers-sidebar.svelte`.

### 3.2 User Listing (`assets/js/pages/settings/users/index.svelte`)
- **Sidebar**:
  - `SidebarHeader` with search input (debounced by 500ms) and `+ New User` button.
  - Renders list of users with `SidebarItem`:
    - `label`: `user.name`
    - `description`: `user.email`
    - `badge`: `user.role` formatted with distinctive color styling (`root` purple/amber, `admin` blue, `support` slate).
    - Preserves query state and filter parameters on navigation.

### 3.3 User Details Pane
- **Header**:
  - User name, avatar/initials, and user ID with a Lucide `Copy` button.
  - **Inline Role `<Select>`**:
    - Uses shadcn-svelte `<Select>` (`Select.Root`, `Select.Trigger`, `Select.Content`, `Select.Item`, `Select.Value`).
    - Options: `root`, `admin`, `support`.
    - Disabled when `current_user.id === user.id && user.role === 'root'`, accompanied by helper text: `"Root users cannot change their own role"`.
    - Triggers `router.put('/ui/admin/settings/users/${user.id}', { role: selectedRole })` on change with `preserveScroll: true` and `preserveState: true`.
  - Actions menu with `DropdownMenu` for "Edit Details" (modifying name/email via `UserUpdateForm`).
- **Profile Details Card**:
  - Displays:
    - Status Badge (Active/Confirmed/Disabled)
    - Full Name
    - Email Address
    - External ID (or "None")
    - Created At (`DateTimeDisplay`)
    - Updated At (`DateTimeDisplay`)
- **Activity & Logs Section**:
  - Placed directly below the Details Card.
  - Section header with Lucide `Activity` icon.
  - Lifecycle milestones timeline:
    - **Account Created**: timestamped with `user.insertedAt`.
    - **Account Confirmed**: timestamped with `user.confirmedAt` (if confirmed).
    - **Last Authenticated**: timestamped with `user.authenticatedAt` (if authenticated).
  - Clean extensible placeholder card for future audit logs: *"No additional audit logs recorded. Future events (logins, role updates, API key events) will appear here."*

---

## 4. Error Handling & Edge Cases
1. **Direct API / Form Tampering**: If a root user attempts to bypass UI disabling and sends a `PUT` payload modifying their own role, the backend rejects it with an Ecto changeset error and flashes an error notification.
2. **Non-existent User**: `Auth.get_user!` gracefully handled or redirected if the user ID in the URL is invalid.
3. **Empty States**: If no users match search filters in the sidebar, an empty state message is displayed.

---

## 5. Testing & Verification Plan

### Automated Tests
- `test/whooks/auth_test.exs`:
  - Enforce root self-demotion guard in `Auth.update_user/3`.
  - Ensure root user can update another user's role.
  - Ensure non-root users cannot promote to root or alter root users.
- `test/whooks_web/controllers/ui/admin/settings/users_controller_test.exs`:
  - `GET /ui/admin/settings/users` assigns `current_user`.
  - `PUT /ui/admin/settings/users/:id` role update success for another user.
  - `PUT /ui/admin/settings/users/:id` role update rejection when root modifies own role.

### Quality Verification
- Run `mix precommit` (compiler checks, formatting, Credo, Dialyzer, and test suite).
