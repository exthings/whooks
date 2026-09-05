# Consumer Portal Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Consumer Portal Dashboard to provide consumers with an overview of webhook delivery KPIs, time-series volume metrics, recent delivery logs with pagination, and endpoint health status.

**Architecture:** A Phoenix controller (`WhooksWeb.UI.Consumer.HomeController`) renders an Inertia Svelte 5 page (`consumers/portal/dashboard.svelte`). The initial page shell renders immediately with filter options, while heavy metrics (`kpis`, `events_metrics`, `events`, `endpoint_health`) are loaded asynchronously via Inertia deferred props. Background polling keeps data synchronized.

**Tech Stack:** Elixir, Phoenix 1.8, Inertia.js, Svelte 5 (runes), TypeScript, Tailwind CSS, shadcn-svelte, LayerChart v2.

**Spec:** `docs/superpowers/specs/2026-09-05-consumer-portal-dashboard-design.md`

## Global Constraints
- Strictly follow Elixir and Phoenix conventions from `AGENTS.md` (Req for HTTP, no index-based list access syntax `list[i]`, explicit `current_scope` assignment, use `start_supervised!/1` in tests, avoid `Process.sleep`).
- Frontend components must adhere to Svelte 5 runes (`$props()`, `$state()`, `$derived()`, `$effect()`) and use `shadcn-svelte` primitives.
- Use `mix precommit` alias when completing changes and fix any warnings or issues.

---

### Task 1: Backend Metrics Query (`Whooks.Metrics.consumer_kpis/2`)

**Files:**
- Modify: `lib/whooks/metrics/metrics.ex`
- Test: `test/whooks/metrics/consumer_kpis_test.exs`

**Interfaces:**
- Consumes: `Whooks.Events.Event`, `Whooks.Endpoints.Endpoint`, `Whooks.Metrics.Utils`
- Produces: `Whooks.Metrics.consumer_kpis(consumer_id, opts \\ [])` returning `{:ok, %{total_events: non_neg_integer(), successful_events: non_neg_integer(), failed_events: non_neg_integer(), success_rate: float(), active_endpoints_count: non_neg_integer()}}`

- [x] **Step 1: Write the failing unit test**

Create `test/whooks/metrics/consumer_kpis_test.exs`:
```elixir
defmodule Whooks.Metrics.ConsumerKpisTest do
  use Whooks.DataCase, async: true

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.TopicsFixtures
  import Whooks.EndpointsFixtures
  import Whooks.EventsFixtures

  alias Whooks.Metrics

  describe "consumer_kpis/2" do
    test "returns zeros when consumer has no events or endpoints" do
      consumer = consumer_fixture()

      assert {:ok, kpis} = Metrics.consumer_kpis(consumer.id)

      assert kpis == %{
               total_events: 0,
               successful_events: 0,
               failed_events: 0,
               success_rate: 100.0,
               active_endpoints_count: 0
             }
    end

    test "calculates correct counts and success rate for a consumer" do
      org = organization_fixture()
      project = project_fixture(%{organization_id: org.id})
      consumer = consumer_fixture(%{organization_id: org.id})
      topic = topic_fixture(%{project_id: project.id})

      # Create endpoints
      _ep1 =
        endpoint_fixture(%{consumer_id: consumer.id, project_id: project.id, status: :enabled})

      _ep2 =
        endpoint_fixture(%{consumer_id: consumer.id, project_id: project.id, status: :enabled})

      # Create events
      _event1 =
        event_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          topic_id: topic.id,
          status: :success
        })

      _event2 =
        event_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          topic_id: topic.id,
          status: :success
        })

      _event3 =
        event_fixture(%{
          consumer_id: consumer.id,
          project_id: project.id,
          topic_id: topic.id,
          status: :failed
        })

      assert {:ok, kpis} = Metrics.consumer_kpis(consumer.id, last: "24h")

      assert kpis.total_events == 3
      assert kpis.successful_events == 2
      assert kpis.failed_events == 1
      assert Float.round(kpis.success_rate, 1) == 66.7
      assert kpis.active_endpoints_count == 2
    end
  end
end
```

- [x] **Step 2: Run test to verify it fails**

Run: `mix test test/whooks/metrics/consumer_kpis_test.exs`
Expected: FAIL with `undefined function consumer_kpis/2`

- [x] **Step 3: Implement `consumer_kpis/2` in `Whooks.Metrics`**

Add to `lib/whooks/metrics/metrics.ex`:
```elixir
  alias Whooks.Events.Event
  alias Whooks.Metrics.Utils

  def consumer_kpis(consumer_id, opts \\ []) do
    last = Keyword.get(opts, :last, "24h")
    project_id = Keyword.get(opts, :project_id)
    start_dt = Utils.parse_last_to_date_time(last)

    events_query =
      from(e in Event,
        where: e.consumer_id == ^consumer_id and e.inserted_at >= ^start_dt,
        group_by: e.status,
        select: {e.status, count(e.id)}
      )

    events_query =
      if project_id do
        from(e in events_query, where: e.project_id == ^project_id)
      else
        events_query
      end

    status_counts = Repo.all(events_query) |> Map.new()

    successful_events = Map.get(status_counts, :success, 0) + Map.get(status_counts, "success", 0)
    failed_events = Map.get(status_counts, :failed, 0) + Map.get(status_counts, "failed", 0)
    total_events = Enum.reduce(status_counts, 0, fn {_status, count}, acc -> acc + count end)

    success_rate =
      if total_events > 0 do
        Float.round((successful_events / total_events) * 100, 1)
      else
        100.0
      end

    endpoints_query =
      from(ep in Endpoint,
        where: ep.consumer_id == ^consumer_id and ep.status == :enabled,
        select: count(ep.id)
      )

    endpoints_query =
      if project_id do
        from(ep in endpoints_query, where: ep.project_id == ^project_id)
      else
        endpoints_query
      end

    active_endpoints_count = Repo.one(endpoints_query) || 0

    {:ok,
     %{
       total_events: total_events,
       successful_events: successful_events,
       failed_events: failed_events,
       success_rate: success_rate,
       active_endpoints_count: active_endpoints_count
     }}
  end
```

- [x] **Step 4: Run test to verify it passes**

Run: `mix test test/whooks/metrics/consumer_kpis_test.exs`
Expected: PASS (2 tests, 0 failures)

- [x] **Step 5: Commit**

```bash
git add lib/whooks/metrics/metrics.ex test/whooks/metrics/consumer_kpis_test.exs
git commit -m "feat(metrics): add consumer_kpis/2 aggregation helper"
```

---

### Task 2: Controller & Integration (`WhooksWeb.UI.Consumer.HomeController`)

**Files:**
- Modify: `lib/whooks_web/controllers/ui/consumer/home_controller.ex`
- Modify: `lib/whooks/events.ex`
- Test: `test/whooks_web/controllers/ui/consumer/home_controller_test.exs`

**Interfaces:**
- Consumes: `Whooks.Metrics`, `Whooks.Projects`, `Whooks.Events`, `Whooks.Endpoints`, `Whooks.Serializer`
- Produces: Inertia render for `"consumers/portal/dashboard"` with `projects`, `filters`, and deferred `kpis`, `events_metrics`, `events` (with `data` and `meta`), and `endpoint_health`.

- [x] **Step 1: Write controller test**

Create `test/whooks_web/controllers/ui/consumer/home_controller_test.exs`:
```elixir
defmodule WhooksWeb.UI.Consumer.HomeControllerTest do
  use WhooksWeb.ConnCase, async: true

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures
  import Inertia.Testing

  setup do
    organization = organization_fixture()
    consumer = consumer_fixture(%{organization_id: organization.id})
    project = project_fixture(%{organization_id: organization.id})

    token = Whooks.Auth.generate_consumer_session_token(consumer)

    conn =
      Phoenix.ConnTest.build_conn()
      |> Phoenix.ConnTest.init_test_session(%{access_token: token})

    %{conn: conn, organization: organization, consumer: consumer, project: project}
  end

  describe "GET /ui/consumers/dashboard" do
    test "renders dashboard page with initial props", %{conn: conn, project: _project} do
      conn = get(conn, ~p"/ui/consumers/dashboard")
      assert html_response(conn, 200) =~ "consumers/portal/dashboard"
      assert inertia_component(conn) == "consumers/portal/dashboard"
    end

    test "accepts filter parameters and exposes filters and projects props", %{
      conn: conn,
      project: project
    } do
      conn = get(conn, ~p"/ui/consumers/dashboard?last=7d&project_id=#{project.id}")
      assert html_response(conn, 200)
      props = inertia_props(conn)
      assert props.filters.last == "7d"
      assert props.filters.projectId == to_string(project.id)
      assert is_list(props.projects)
    end

    test "resolves deferred props successfully", %{conn: conn} do
      version =
        ["/assets/app.js"]
        |> Enum.map_join(&WhooksWeb.Endpoint.static_path(&1))
        |> then(&Base.encode16(:crypto.hash(:md5, &1), case: :lower))

      conn =
        conn
        |> put_req_header("x-inertia", "true")
        |> put_req_header("x-inertia-version", version)
        |> put_req_header("x-inertia-partial-component", "consumers/portal/dashboard")
        |> put_req_header(
          "x-inertia-partial-data",
          "kpis,eventsMetrics,events,endpointHealth"
        )
        |> get(~p"/ui/consumers/dashboard")

      assert conn.status == 200
      props = json_response(conn, 200)["props"]
      assert is_map(props["kpis"])
      assert is_map(props["eventsMetrics"])
      assert is_map(props["events"])
      assert is_list(props["events"]["data"])
      assert is_list(props["endpointHealth"])
    end
  end
end
```

- [x] **Step 2: Run test to verify behavior**

Run: `mix test test/whooks_web/controllers/ui/consumer/home_controller_test.exs`
Expected: PASS

- [x] **Step 3: Update `WhooksWeb.UI.Consumer.HomeController` & `Whooks.Events`**

In `lib/whooks/events.ex`, support the `{:last, last}` filter option:
```elixir
      {:last, last}, q ->
        where(
          q,
          [e, da, s],
          e.inserted_at >= ^Utils.parse_last_to_date_time(last) and
            e.inserted_at <= fragment("now()")
        )
```

In `lib/whooks_web/controllers/ui/consumer/home_controller.ex`:
```elixir
defmodule WhooksWeb.UI.Consumer.HomeController do
  use WhooksWeb, :controller

  alias Whooks.Repo
  alias Whooks.Projects
  alias Whooks.Events
  alias Whooks.Endpoints
  alias Whooks.Metrics
  alias Whooks.Serializer

  require Logger

  @last_to_interval %{
    "1h" => "minute",
    "12h" => "hour",
    "24h" => "hour",
    "48h" => "hour",
    "7d" => "day",
    "1w" => "day",
    "30d" => "day",
    "1mo" => "day"
  }

  def index(conn, params) do
    scope = conn.assigns.current_scope
    consumer = scope.consumer

    last = Map.get(params, "last", "24h")
    project_id = Map.get(params, "project_id")
    project_id = if project_id in ["", "all", nil], do: nil, else: project_id
    interval = Map.get(@last_to_interval, last, "hour")

    {:ok, {projects, _meta}} =
      Projects.list(%{"page_size" => 100}, organization_id: consumer.organization_id)

    conn
    |> assign_prop(:projects, Serializer.to_map(projects))
    |> assign_prop(:filters, %{last: last, project_id: project_id})
    |> assign_prop(
      :kpis,
      inertia_defer(fn ->
        opts = [last: last] ++ if(project_id, do: [project_id: project_id], else: [])
        {:ok, kpis} = Metrics.consumer_kpis(consumer.id, opts)
        kpis
      end)
    )
    |> assign_prop(
      :events_metrics,
      inertia_defer(fn ->
        opts =
          [
            consumer_id: consumer.id,
            last: last,
            interval: interval
          ] ++ if(project_id, do: [project_id: project_id], else: [])

        {:ok, events_stats} = Metrics.EventStats.timeseries(opts)

        %{
          data: events_stats,
          interval: interval,
          last: last
        }
      end)
    )
    |> assign_prop(
      :events,
      inertia_defer(fn ->
        Events.list(scope, %{"page_size" => 5}, last: last)
        |> case do
          {:ok, {events, meta}} ->
            %{data: Serializer.to_map(events), meta: Serializer.to_map(meta)}

          _ ->
            %{data: [], meta: %{}}
        end
      end)
    )
    |> assign_prop(
      :endpoint_health,
      inertia_defer(fn ->
        Endpoints.list(scope, %{"page_size" => 5})
        |> case do
          {:ok, {endpoints, _meta}} ->
            endpoints
            |> Repo.preload(subscriptions: [:topic])
            |> Serializer.to_map()

          _ ->
            []
        end
      end)
    )
    |> render_inertia("consumers/portal/dashboard")
  end
end
```

- [x] **Step 4: Run test to verify it passes**

Run: `mix test test/whooks_web/controllers/ui/consumer/home_controller_test.exs`
Expected: PASS (3 tests, 0 failures)

- [x] **Step 5: Commit**

```bash
git add lib/whooks_web/controllers/ui/consumer/home_controller.ex lib/whooks/events.ex test/whooks_web/controllers/ui/consumer/home_controller_test.exs
git commit -m "feat(portal): add dashboard data and deferred props in consumer HomeController"
```

---

### Task 3: Frontend Dashboard UI Implementation (`assets/js/pages/consumers/portal/dashboard.svelte`)

**Files:**
- Modify: `assets/js/pages/consumers/portal/dashboard.svelte`
- Components used: `assets/js/components/events-table.svelte`, `assets/js/components/section.svelte`, `assets/js/components/charts/bar-chart-events.svelte`

**Interfaces:**
- Consumes:
  - Immediate Props: `projects?: Project[]`, `filters?: { last: string, projectId?: string | null }`
  - Deferred Props:
    - `kpis?: { totalEvents: number, successfulEvents: number, failedEvents: number, successRate: number, activeEndpointsCount: number }`
    - `eventsMetrics?: { data: Analytics[], interval: string, last: string }`
    - `events?: { data: Event[], meta: Meta }`
    - `endpointHealth?: (Endpoint & { subscriptions?: any[] })[]`
- Produces: Fully responsive Svelte 5 Dashboard layout with 3-column top section (2x2 KPI grid + 2-col performance chart) and full EventsTable + Endpoints Section.

- [x] **Step 1: Inspect existing types and chart components**

Ensure `assets/js/types/index.ts` exports `Analytics`, `Project`, `Event`, `Endpoint`, `Meta`.
Ensure `BarChartEvents` from `$components/charts` integrates properly with `eventsMetrics.data`.

- [x] **Step 2: Implement `dashboard.svelte` with Svelte 5 Runes & shadcn-svelte**

Write `assets/js/pages/consumers/portal/dashboard.svelte`:
- Header Toolbar: Title and description with Project Selector (`Select.Root`) and Time Range Selector (`24h`, `7d`, `30d`).
- Reactive filters with `$derived`:
  - `selectedLast = $derived(filters?.last ?? "24h")`
  - `selectedProjectId = $derived(filters?.projectId ?? "all")`
- Partial reload:
  - `router.reload({ data: { last, project_id: projectId === "all" ? "" : projectId }, only: ["filters", "kpis", "eventsMetrics", "endpointHealth", "events"] })`
- Top 3-Column Layout (`grid grid-cols-3 gap-4`):
  - Column 1: 2x2 Grid with 4 KPI cards (Total Deliveries, Success Rate %, Failed Deliveries, Active Endpoints) inside `<Deferred data="kpis">` with skeleton fallback.
  - Columns 2-3 (`col-span-2`): Delivery Performance Chart card inside `<Deferred data="eventsMetrics">` with `BarChartEvents`.
- Bottom Section:
  - `<EventsTable propsKey="events" columnVisibility={["insertedAt", "id", "consumer", "topic", "status", "tags"]} />`
  - `<Section title="Endpoints">` containing Endpoint Health list card with `<Deferred data="endpointHealth">`.

- [x] **Step 3: Validate Frontend Build / Compilation**

Run: `pnpm --dir assets run build`
Expected: Clean build without Svelte/TypeScript syntax errors.

- [x] **Step 4: Commit**

```bash
git add assets/js/pages/consumers/portal/dashboard.svelte assets/js/components/section.svelte assets/js/components/events-table.svelte
git commit -m "feat(portal): implement consumer portal dashboard UI with Svelte 5"
```

---

### Task 4: Full Suite Verification & Formatting

**Files:**
- Codebase-wide linting and precommit checks

- [x] **Step 1: Run compile --warnings-as-errors and mix format**

Run: `mix compile --warnings-as-errors && mix format`
Expected: Clean compilation with 0 warnings, code formatted.

- [x] **Step 2: Commit any formatting or minor fixes**

```bash
git commit -am "chore: formatting and precommit fixes for consumer portal dashboard"
```
