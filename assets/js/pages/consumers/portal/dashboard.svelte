<script lang="ts" module>
  export { default as layout } from "$layouts/portal.svelte";
</script>

<script lang="ts">
  import type { Project, Event, Endpoint, Analytics } from "$types";
  import type { BadgeStatusVariant } from "$components/badge-status.svelte";
  import BadgeStatus from "$components/badge-status.svelte";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import { BarChartEvents } from "$components/charts";
  import * as Card from "$lib/components/ui/card";
  import * as Select from "$lib/components/ui/select";
  import { Skeleton } from "$lib/components/ui/skeleton";
  import { buttonVariants } from "$lib/components/ui/button";
  import { Link, Deferred, router, usePoll } from "@inertiajs/svelte";
  import {
    ActivityIcon,
    CheckCircle2Icon,
    AlertTriangleIcon,
    CableIcon,
    ArrowRightIcon,
    PlusIcon,
    LayersIcon,
    InboxIcon,
  } from "lucide-svelte";

  type KPIs = {
    totalEvents: number;
    successfulEvents: number;
    failedEvents: number;
    successRate: number;
    activeEndpointsCount: number;
  };

  type EventsMetrics = {
    data: Analytics[];
    interval: "minute" | "hour" | "day";
    last: string;
  };

  type Props = {
    projects?: Project[];
    filters?: {
      last: string;
      projectId?: string | null;
    };
    kpis?: KPIs;
    eventsMetrics?: EventsMetrics;
    recentEvents?: (Event & { topic?: { name: string } })[];
    endpointHealth?: (Endpoint & { subscriptions?: any[] })[];
  };

  let {
    projects = [],
    filters = { last: "24h", projectId: null },
    kpis,
    eventsMetrics,
    recentEvents = [],
    endpointHealth = [],
  }: Props = $props();

  const TIME_RANGES = [
    { value: "24h", label: "Last 24 hours" },
    { value: "7d", label: "Last 7 days" },
    { value: "30d", label: "Last 30 days" },
  ];

  const STATUS_VARIANT: Record<string, BadgeStatusVariant> = {
    pending: "outline",
    scheduled: "info",
    processing: "warning",
    retry: "warning",
    success: "success",
    failed: "destructive",
    partial_success: "warning",
  };

  let selectedLast = $state(filters?.last ?? "24h");
  let selectedProjectId = $state(filters?.projectId ?? "all");

  $effect(() => {
    if (filters?.last) selectedLast = filters.last;
    if (filters?.projectId) selectedProjectId = filters.projectId;
    else if (filters?.projectId === null) selectedProjectId = "all";
  });

  const selectedRangeLabel = $derived(
    TIME_RANGES.find((r) => r.value === selectedLast)?.label ?? "Last 24 hours",
  );

  const selectedProjectLabel = $derived(
    selectedProjectId === "all"
      ? "All Projects"
      : (projects.find((p) => p.id === selectedProjectId)?.name ??
          "Select Project"),
  );

  function handleLastChange(val: string | undefined) {
    if (!val) return;
    selectedLast = val;
    triggerReload(val, selectedProjectId);
  }

  function handleProjectChange(val: string | undefined) {
    if (!val) return;
    selectedProjectId = val;
    triggerReload(selectedLast, val);
  }

  function triggerReload(last: string, projectId: string) {
    router.reload({
      data: {
        last,
        project_id: projectId === "all" ? "" : projectId,
      },
      only: ["kpis", "eventsMetrics", "recentEvents"],
    });
  }

  usePoll(10000);
</script>

<svelte:head>
  <title>Whooks - Consumer Dashboard</title>
</svelte:head>

<div class="flex-1 flex flex-col gap-6 p-6 lg:p-8 w-full">
  <!-- Page Header & Filter Toolbar -->
  <div
    class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b"
  >
    <div>
      <h1 class="text-2xl font-bold tracking-tight">Dashboard</h1>
      <p class="text-sm text-muted-foreground mt-1">
        Monitor webhook delivery health, volume, and active endpoints.
      </p>
    </div>

    <div class="flex flex-wrap items-center gap-3">
      <!-- Project Filter -->
      <Select.Root
        type="single"
        name="projectFilter"
        bind:value={selectedProjectId}
        onValueChange={handleProjectChange}
      >
        <Select.Trigger class="w-44 text-xs h-9">
          <span class="truncate">{selectedProjectLabel}</span>
        </Select.Trigger>
        <Select.Content>
          <Select.Group>
            <Select.Item value="all" label="All Projects">
              All Projects
            </Select.Item>
            {#each projects as project (project.id)}
              <Select.Item value={project.id} label={project.name}>
                {project.name}
              </Select.Item>
            {/each}
          </Select.Group>
        </Select.Content>
      </Select.Root>

      <!-- Time Range Filter -->
      <Select.Root
        type="single"
        name="timeRangeFilter"
        bind:value={selectedLast}
        onValueChange={handleLastChange}
      >
        <Select.Trigger class="w-36 text-xs h-9">
          <span class="truncate">{selectedRangeLabel}</span>
        </Select.Trigger>
        <Select.Content>
          <Select.Group>
            {#each TIME_RANGES as range (range.value)}
              <Select.Item value={range.value} label={range.label}>
                {range.label}
              </Select.Item>
            {/each}
          </Select.Group>
        </Select.Content>
      </Select.Root>
    </div>
  </div>

  <!-- KPI Cards Grid -->
  <Deferred data="kpis">
    {#snippet fallback()}
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {#each Array(4) as _}
          <Card.Root class="p-5">
            <div class="flex items-center justify-between">
              <Skeleton class="h-4 w-24" />
              <Skeleton class="size-8 rounded-md" />
            </div>
            <Skeleton class="h-8 w-16 mt-3" />
            <Skeleton class="h-3 w-32 mt-2" />
          </Card.Root>
        {/each}
      </div>
    {/snippet}

    {#if kpis}
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Card 1: Total Deliveries -->
        <Card.Root
          class="p-5 relative overflow-hidden transition-all hover:border-muted-foreground/30"
        >
          <div class="flex items-center justify-between text-muted-foreground">
            <span class="text-xs font-medium uppercase tracking-wider"
              >Total Deliveries</span
            >
            <div
              class="size-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center"
            >
              <ActivityIcon class="size-4" />
            </div>
          </div>
          <div class="mt-3 text-2xl font-bold tracking-tight">
            {kpis.totalEvents.toLocaleString()}
          </div>
          <p class="text-xs text-muted-foreground mt-1">
            Delivered in selected timeframe
          </p>
        </Card.Root>

        <!-- Card 2: Success Rate -->
        <Card.Root
          class="p-5 relative overflow-hidden transition-all hover:border-muted-foreground/30"
        >
          <div class="flex items-center justify-between text-muted-foreground">
            <span class="text-xs font-medium uppercase tracking-wider"
              >Success Rate</span
            >
            <div
              class="size-8 rounded-lg bg-green-500/10 text-green-600 dark:text-green-400 flex items-center justify-center"
            >
              <CheckCircle2Icon class="size-4" />
            </div>
          </div>
          <div
            class="mt-3 text-2xl font-bold tracking-tight flex items-baseline gap-1.5"
          >
            <span
              class={kpis.successRate >= 95
                ? "text-green-600 dark:text-green-400"
                : "text-amber-600 dark:text-amber-400"}
            >
              {kpis.successRate.toFixed(1)}%
            </span>
          </div>
          <p class="text-xs text-muted-foreground mt-1">
            {kpis.successfulEvents.toLocaleString()} successful
          </p>
        </Card.Root>

        <!-- Card 3: Failed Deliveries -->
        <Card.Root
          class="p-5 relative overflow-hidden transition-all hover:border-muted-foreground/30"
        >
          <div class="flex items-center justify-between text-muted-foreground">
            <span class="text-xs font-medium uppercase tracking-wider"
              >Failed Deliveries</span
            >
            <div
              class={`size-8 rounded-lg flex items-center justify-center ${kpis.failedEvents > 0 ? "bg-destructive/10 text-destructive" : "bg-muted text-muted-foreground"}`}
            >
              <AlertTriangleIcon class="size-4" />
            </div>
          </div>
          <div class="mt-3 text-2xl font-bold tracking-tight">
            <span class={kpis.failedEvents > 0 ? "text-destructive" : ""}>
              {kpis.failedEvents.toLocaleString()}
            </span>
          </div>
          <p class="text-xs text-muted-foreground mt-1">
            {kpis.failedEvents > 0
              ? "Requires review or endpoint fix"
              : "No failed delivery attempts"}
          </p>
        </Card.Root>

        <!-- Card 4: Active Endpoints -->
        <Card.Root
          class="p-5 relative overflow-hidden transition-all hover:border-muted-foreground/30"
        >
          <div class="flex items-center justify-between text-muted-foreground">
            <span class="text-xs font-medium uppercase tracking-wider"
              >Active Endpoints</span
            >
            <div
              class="size-8 rounded-lg bg-blue-500/10 text-blue-600 dark:text-blue-400 flex items-center justify-center"
            >
              <CableIcon class="size-4" />
            </div>
          </div>
          <div class="mt-3 text-2xl font-bold tracking-tight">
            {kpis.activeEndpointsCount}
          </div>
          <p class="text-xs text-muted-foreground mt-1">
            Registered webhook listeners
          </p>
        </Card.Root>
      </div>
    {/if}
  </Deferred>

  <!-- Delivery Volume Chart Section -->
  <Card.Root class="p-6 shadow-none">
    <div
      class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-4 mb-2 border-b border-border/50"
    >
      <div>
        <h2 class="text-base font-semibold tracking-tight">
          Delivery Performance
        </h2>
        <p class="text-xs text-muted-foreground mt-0.5">
          Dispatched webhook events over time for the selected interval ({selectedLast})
        </p>
      </div>
    </div>

    <Deferred data="eventsMetrics">
      {#snippet fallback()}
        <Skeleton class="h-64 w-full rounded-md" />
      {/snippet}

      {#if eventsMetrics?.data && eventsMetrics.data.length > 0}
        <div class="h-64 w-full">
          <BarChartEvents
            data={eventsMetrics.data}
            interval={eventsMetrics.interval}
          />
        </div>
      {:else}
        <div
          class="h-56 flex flex-col items-center justify-center text-center p-6 border border-dashed rounded-lg"
        >
          <InboxIcon class="size-8 text-muted-foreground mb-2 stroke-[1.5]" />
          <p class="text-sm font-medium text-muted-foreground">
            No delivery metrics recorded
          </p>
          <p class="text-xs text-muted-foreground/70 mt-1">
            Events will automatically populate here once dispatched to your
            endpoints.
          </p>
        </div>
      {/if}
    </Deferred>
  </Card.Root>

  <!-- Bottom Split Section: Recent Events & Endpoint Health -->
  <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
    <!-- Left: Recent Deliveries (2/3 width) -->
    <Card.Root class="lg:col-span-2 shadow-none p-5 flex flex-col">
      <div
        class="flex items-center justify-between pb-3 mb-3 border-b border-border/50"
      >
        <div>
          <h2 class="text-base font-semibold tracking-tight">
            Recent Deliveries
          </h2>
          <p class="text-xs text-muted-foreground mt-0.5">
            Latest events received by your configured webhooks
          </p>
        </div>
        <Link
          href="/ui/consumers/events"
          class={buttonVariants({ variant: "ghost", size: "sm" })}
        >
          <span>View all</span>
          <ArrowRightIcon class="size-3.5 ml-1" />
        </Link>
      </div>

      <Deferred data="recentEvents">
        {#snippet fallback()}
          <div class="space-y-3">
            {#each Array(4) as _}
              <div
                class="flex items-center justify-between py-2 border-b border-border/40"
              >
                <div class="space-y-1">
                  <Skeleton class="h-4 w-32" />
                  <Skeleton class="h-3 w-48" />
                </div>
                <Skeleton class="h-5 w-16 rounded-full" />
              </div>
            {/each}
          </div>
        {/snippet}

        {#if recentEvents && recentEvents.length > 0}
          <div class="divide-y divide-border/50 -mx-1">
            {#each recentEvents as event (event.id)}
              <Link
                href={`/ui/consumers/events/${event.id}`}
                class="flex items-center justify-between py-3 px-2 rounded-md hover:bg-muted/50 transition-colors group"
              >
                <div class="min-w-0 pr-4">
                  <div class="flex items-center gap-2">
                    <span
                      class="text-sm font-medium truncate group-hover:text-primary transition-colors"
                    >
                      {event.topic?.name ?? "Webhook Event"}
                    </span>
                    <span
                      class="font-mono text-[11px] text-muted-foreground/80 truncate"
                    >
                      {event.uid ?? event.id}
                    </span>
                  </div>
                  <div
                    class="text-xs text-muted-foreground mt-0.5 flex items-center gap-2"
                  >
                    <DateTimeDisplay value={event.insertedAt} />
                  </div>
                </div>

                <div class="flex items-center gap-3 shrink-0">
                  <BadgeStatus
                    variant={STATUS_VARIANT[event.status] ?? "default"}
                    label={event.status}
                  />
                  <ArrowRightIcon
                    class="size-3.5 text-muted-foreground/40 group-hover:text-foreground group-hover:translate-x-0.5 transition-all"
                  />
                </div>
              </Link>
            {/each}
          </div>
        {:else}
          <div
            class="py-12 flex flex-col items-center justify-center text-center"
          >
            <InboxIcon class="size-8 text-muted-foreground mb-2 stroke-[1.5]" />
            <p class="text-sm font-medium text-muted-foreground">
              No recent events
            </p>
            <p class="text-xs text-muted-foreground/70 mt-1 max-w-sm">
              When external webhooks are triggered, they will appear here in
              real time.
            </p>
          </div>
        {/if}
      </Deferred>
    </Card.Root>

    <!-- Right: Endpoint Health (1/3 width) -->
    <Card.Root class="lg:col-span-1 shadow-none p-5 flex flex-col">
      <div
        class="flex items-center justify-between pb-3 mb-3 border-b border-border/50"
      >
        <div>
          <h2 class="text-base font-semibold tracking-tight">Endpoints</h2>
          <p class="text-xs text-muted-foreground mt-0.5">
            Active destinations
          </p>
        </div>
        <Link
          href="/ui/consumers/endpoints"
          class={buttonVariants({ variant: "ghost", size: "sm" })}
        >
          <span>Manage</span>
          <ArrowRightIcon class="size-3.5 ml-1" />
        </Link>
      </div>

      <Deferred data="endpointHealth">
        {#snippet fallback()}
          <div class="space-y-3">
            {#each Array(3) as _}
              <div class="py-2 space-y-1.5 border-b border-border/40">
                <Skeleton class="h-4 w-full" />
                <Skeleton class="h-3 w-20" />
              </div>
            {/each}
          </div>
        {/snippet}

        {#if endpointHealth && endpointHealth.length > 0}
          <div class="divide-y divide-border/50 -mx-1">
            {#each endpointHealth as endpoint (endpoint.id)}
              <Link
                href={`/ui/consumers/endpoints/${endpoint.id}`}
                class="py-3 px-2 flex flex-col gap-1.5 rounded-md hover:bg-muted/50 transition-colors group"
              >
                <div class="flex items-center justify-between gap-2">
                  <span
                    class="font-mono text-xs text-foreground truncate group-hover:text-primary transition-colors"
                    title={endpoint.url}
                  >
                    {endpoint.url}
                  </span>
                  <BadgeStatus
                    variant={endpoint.status === "enabled"
                      ? "success"
                      : "warning"}
                    label={endpoint.status}
                  />
                </div>

                <div
                  class="flex items-center gap-3 text-xs text-muted-foreground"
                >
                  <span class="flex items-center gap-1">
                    <LayersIcon class="size-3" />
                    {endpoint.subscriptions?.length ?? 0} topics
                  </span>
                  {#if endpoint.description}
                    <span class="truncate max-w-[150px]">
                      {endpoint.description}
                    </span>
                  {/if}
                </div>
              </Link>
            {/each}
          </div>
        {:else}
          <div
            class="py-10 flex flex-col items-center justify-center text-center"
          >
            <CableIcon class="size-8 text-muted-foreground mb-2 stroke-[1.5]" />
            <p class="text-sm font-medium text-muted-foreground">
              No endpoints configured
            </p>
            <p class="text-xs text-muted-foreground/70 mt-1 mb-4">
              Add your first endpoint destination to receive webhook events.
            </p>
            <Link
              href="/ui/consumers/endpoints"
              class={buttonVariants({ size: "sm" })}
            >
              <PlusIcon class="size-3.5 mr-1" />
              <span>Add Endpoint</span>
            </Link>
          </div>
        {/if}
      </Deferred>
    </Card.Root>
  </div>
</div>
