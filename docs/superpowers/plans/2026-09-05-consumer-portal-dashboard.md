# Consumer Portal Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Consumer Portal Dashboard to provide consumers with an overview of webhook delivery KPIs, time-series volume metrics, recent delivery logs, and endpoint health status.

**Architecture:** A Phoenix controller (`WhooksWeb.UI.Consumer.HomeController`) renders an Inertia Svelte 5 page (`consumers/portal/dashboard.svelte`). The initial page shell renders immediately with filter options, while heavy metrics (`kpis`, `events_metrics`, `recent_events`, `endpoint_health`) are loaded asynchronously via Inertia deferred props. Background polling (`usePoll(10000)`) keeps data synchronized.

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

- [ ] **Step 1: Write the failing unit test**

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
      _ep1 = endpoint_fixture(%{consumer_id: consumer.id, project_id: project.id, status: :active})
      _ep2 = endpoint_fixture(%{consumer_id: consumer.id, project_id: project.id, status: :active})

      # Create events
      _event1 = event_fixture(%{consumer_id: consumer.id, project_id: project.id, topic_id: topic.id, status: "delivered"})
      _event2 = event_fixture(%{consumer_id: consumer.id, project_id: project.id, topic_id: topic.id, status: "delivered"})
      _event3 = event_fixture(%{consumer_id: consumer.id, project_id: project.id, topic_id: topic.id, status: "failed"})

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

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/whooks/metrics/consumer_kpis_test.exs`
Expected: FAIL with `undefined function consumer_kpis/2`

- [ ] **Step 3: Implement `consumer_kpis/2` in `Whooks.Metrics`**

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

    successful_events = Map.get(status_counts, "delivered", 0)
    failed_events = Map.get(status_counts, "failed", 0)
    total_events = Enum.reduce(status_counts, 0, fn {_status, count}, acc -> acc + count end)

    success_rate =
      if total_events > 0 do
        Float.round((successful_events / total_events) * 100, 1)
      else
        100.0
      end

    endpoints_query =
      from(ep in Endpoint,
        where: ep.consumer_id == ^consumer_id and ep.status == :active,
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

- [ ] **Step 4: Run test to verify it passes**

Run: `mix test test/whooks/metrics/consumer_kpis_test.exs`
Expected: PASS (2 tests, 0 failures)

- [ ] **Step 5: Commit**

```bash
git add lib/whooks/metrics/metrics.ex test/whooks/metrics/consumer_kpis_test.exs
git commit -m "feat(metrics): add consumer_kpis/2 aggregation helper"
```

---

### Task 2: Controller & Integration (`WhooksWeb.UI.Consumer.HomeController`)

**Files:**
- Modify: `lib/whooks_web/controllers/ui/consumer/home_controller.ex`
- Test: `test/whooks_web/controllers/ui/consumer/home_controller_test.exs`

**Interfaces:**
- Consumes: `Whooks.Metrics`, `Whooks.Projects`, `Whooks.Events`, `Whooks.Endpoints`, `Whooks.Serializer`
- Produces: Inertia render for `"consumers/portal/dashboard"` with `projects`, `filters`, and deferred `kpis`, `events_metrics`, `recent_events`, and `endpoint_health`.

- [ ] **Step 1: Write controller test**

Create `test/whooks_web/controllers/ui/consumer/home_controller_test.exs`:
```elixir
defmodule WhooksWeb.UI.Consumer.HomeControllerTest do
  use WhooksWeb.ConnCase, async: true

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures
  import Whooks.AuthFixtures

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
    test "renders dashboard page with initial props", %{conn: conn, project: project} do
      conn = get(conn, ~p"/ui/consumers/dashboard")
      assert html_response(conn, 200) =~ "consumers/portal/dashboard"
    end

    test "accepts filter parameters", %{conn: conn, project: project} do
      conn = get(conn, ~p"/ui/consumers/dashboard?last=7d&project_id=#{project.id}")
      assert html_response(conn, 200) =~ "consumers/portal/dashboard"
    end
  end
end
```

- [ ] **Step 2: Run test to verify initial behavior**

Run: `mix test test/whooks_web/controllers/ui/consumer/home_controller_test.exs`
Expected: PASS (verifies existing placeholder renders, but does not yet supply required dashboard props)

- [ ] **Step 3: Update `WhooksWeb.UI.Consumer.HomeController`**

Modify `lib/whooks_web/controllers/ui/consumer/home_controller.ex`:
```elixir
defmodule WhooksWeb.UI.Consumer.HomeController do
  use WhooksWeb, :controller

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
        opts = [
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
      :recent_events,
      inertia_defer(fn ->
        opts = [consumer_id: consumer.id] ++ if(project_id, do: [project_id: project_id], else: [])

        Events.list(%{"page_size" => 8}, opts)
        |> case do
          {:ok, {events, _meta}} -> Serializer.to_map(events)
          _ -> []
        end
      end)
    )
    |> assign_prop(
      :endpoint_health,
      inertia_defer(fn ->
        Endpoints.list(scope, %{"page_size" => 5})
        |> case do
          {:ok, {endpoints, _meta}} -> Serializer.to_map(endpoints)
          _ -> []
        end
      end)
    )
    |> render_inertia("consumers/portal/dashboard")
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mix test test/whooks_web/controllers/ui/consumer/home_controller_test.exs`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/whooks_web/controllers/ui/consumer/home_controller.ex test/whooks_web/controllers/ui/consumer/home_controller_test.exs
git commit -m "feat(portal): add dashboard data and deferred props in consumer HomeController"
```

---

### Task 3: Frontend Dashboard UI Implementation (`assets/js/pages/consumers/portal/dashboard.svelte`)

**Files:**
- Modify: `assets/js/pages/consumers/portal/dashboard.svelte`
- Create/Modify helper component if needed: `assets/js/components/charts/bar-chart-events.svelte`

**Interfaces:**
- Consumes:
  - Immediate Props: `projects: Project[]`, `filters: { last: string, project_id: string | null }`
  - Deferred Props: `kpis: { total_events: number, successful_events: number, failed_events: number, success_rate: number, active_endpoints_count: number }`
  - `events_metrics: { data: Analytics[], interval: string, last: string }`
  - `recent_events: Event[]`
  - `endpoint_health: Endpoint[]`
- Produces: Fully interactive Svelte 5 Dashboard page with filter bar, KPI cards, delivery volume chart, recent deliveries table, endpoint health list, and `usePoll(10000)`.

- [ ] **Step 1: Inspect existing types and chart components**

Ensure `assets/js/types/index.ts` exports `Analytics`, `Project`, `Event`, `Endpoint`.
Ensure `BarChartEvents` from `$components/charts` or `LayerChart` integrates properly with `events_metrics.data`.

- [ ] **Step 2: Implement `dashboard.svelte` with Svelte 5 Runes & shadcn-svelte**

Write `assets/js/pages/consumers/portal/dashboard.svelte` using runes (`$props()`, `$state()`, `$derived()`):
- Top header with Title and Filter Bar (Project selector + Time range selector: 24h, 7d, 30d).
- Handling filter changes via `router.reload({ data: { last, project_id }, only: ['kpis', 'events_metrics', 'recent_events'] })`.
- KPI Cards with `<Deferred data={['kpis']}>` and `<Skeleton>` fallback cards:
  - Total Deliveries
  - Success Rate %
  - Failed Deliveries
  - Active Endpoints
- Timeseries Volume & Status Chart with `<Deferred data={['events_metrics']}>` and `<Skeleton>` fallback.
- Bottom Split Section:
  - 2/3 column: Recent Events with `BadgeStatus`, topic name, event ID, `DateTimeDisplay`, and "View all events →" link to `/ui/consumers/events`.
  - 1/3 column: Endpoint Health with URL (truncated mono font), status indicator, subscription count, and link to `/ui/consumers/endpoints`.
- Real-time updates: `usePoll(10000)`.

- [ ] **Step 3: Validate Frontend Build / Compilation**

Run: `npm --prefix assets run check` or `npm --prefix assets run build`
Expected: Clean build without Svelte/TypeScript syntax errors.

- [ ] **Step 4: Commit**

```bash
git add assets/js/pages/consumers/portal/dashboard.svelte
git commit -m "feat(portal): implement consumer portal dashboard UI with Svelte 5"
```

---

### Task 4: Full Suite Verification & Formatting

**Files:**
- Codebase-wide linting and precommit checks

- [ ] **Step 1: Run mix precommit alias**

Run: `mix precommit`
Expected: All tests pass, formatter clean, no compilation warnings.

- [ ] **Step 2: Commit any formatting or minor fixes if needed**

```bash
git commit -am "chore: formatting and precommit fixes for consumer portal dashboard"
```
