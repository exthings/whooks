<script lang="ts">
  import type { Meta } from "$types";
  import { Deferred } from "@inertiajs/svelte";
  import * as Card from "$lib/components/ui/card";
  import BadgeStatus from "$components/badge-status.svelte";
  import Skeleton from "$lib/components/ui/skeleton/skeleton.svelte";
  import { getSuccessRateLabel } from "$common";
  import {
    ActivityIcon,
    CircleCheckIcon,
    TimerIcon,
    WebhookIcon,
  } from "lucide-svelte";

  type EventsKpi = {
    totalAttempts: number;
    successRate: number;
    p95LatencyMs: number;
    successCount: number;
    failedCount: number;
  };

  type Props = {
    events?: { meta: Meta };
    eventsKpi?: EventsKpi;
    subscriptionsCount?: number;
  };

  const { events, eventsKpi, subscriptionsCount }: Props = $props();

  const successRateLabel = $derived(
    eventsKpi && getSuccessRateLabel(eventsKpi.successRate),
  );
</script>

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
  <Card.Root class="shadow-none py-4 gap-2">
    <Card.Header
      class="flex flex-row items-center justify-between pb-1 space-y-0"
    >
      <Card.Title
        class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
      >
        Total events
      </Card.Title>
      <div class="rounded-md bg-muted/60 p-1.5 text-muted-foreground">
        <ActivityIcon class="size-4" />
      </div>
    </Card.Header>
    <Card.Content class="pt-0">
      <Deferred data="events">
        {#snippet fallback()}
          <div class="space-y-1.5">
            <Skeleton class="h-8 w-24" />
            <Skeleton class="h-3.5 w-32" />
          </div>
        {/snippet}
        <div class="text-2xl lg:text-3xl font-bold tracking-tight">
          {events?.meta?.totalCount != null
            ? events.meta.totalCount.toLocaleString()
            : "0"}
        </div>
        <p class="text-xs text-muted-foreground mt-1">
          {eventsKpi?.totalAttempts != null
            ? `${eventsKpi.totalAttempts.toLocaleString()} deliveries attempted`
            : "Events received in period"}
        </p>
      </Deferred>
    </Card.Content>
  </Card.Root>

  <Card.Root class="shadow-none py-4 gap-2">
    <Card.Header
      class="flex flex-row items-center justify-between pb-1 space-y-0"
    >
      <Card.Title
        class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
      >
        Success rate
      </Card.Title>
      <div class="rounded-md bg-muted/60 p-1.5 text-muted-foreground">
        <CircleCheckIcon class="size-4" />
      </div>
    </Card.Header>
    <Card.Content class="pt-0">
      <Deferred data="eventsKpi">
        {#snippet fallback()}
          <div class="space-y-1.5">
            <Skeleton class="h-8 w-24" />
            <Skeleton class="h-3.5 w-28" />
          </div>
        {/snippet}
        <div
          class="text-2xl lg:text-3xl font-bold tracking-tight flex items-baseline gap-2"
        >
          <span
            >{eventsKpi?.successRate != null
              ? `${Math.round(eventsKpi.successRate)}%`
              : "-"}</span
          >
          {#if eventsKpi?.successRate != null && successRateLabel}
            <BadgeStatus
              label={successRateLabel.label}
              variant={successRateLabel.variant}
            />
          {/if}
        </div>
        <p class="text-xs text-muted-foreground mt-1">
          {#if eventsKpi && eventsKpi.failedCount > 0}
            <span class="font-medium text-red-600 dark:text-red-400"
              >{eventsKpi.failedCount.toLocaleString()}</span
            > failed deliveries attempts
          {:else}
            <span
              class="text-emerald-600 dark:text-emerald-400 font-medium"
              >0 failed</span
            > deliveries
          {/if}
        </p>
      </Deferred>
    </Card.Content>
  </Card.Root>

  <Card.Root class="shadow-none py-4 gap-2">
    <Card.Header
      class="flex flex-row items-center justify-between pb-1 space-y-0"
    >
      <Card.Title
        class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
      >
        P95 latency
      </Card.Title>
      <div class="rounded-md bg-muted/60 p-1.5 text-muted-foreground">
        <TimerIcon class="size-4" />
      </div>
    </Card.Header>
    <Card.Content class="pt-0">
      <Deferred data="eventsKpi">
        {#snippet fallback()}
          <div class="space-y-1.5">
            <Skeleton class="h-8 w-24" />
            <Skeleton class="h-3.5 w-28" />
          </div>
        {/snippet}
        <div class="text-2xl lg:text-3xl font-bold tracking-tight">
          {eventsKpi?.p95LatencyMs != null
            ? `${Math.round(eventsKpi.p95LatencyMs)} ms`
            : "-"}
        </div>
        <p class="text-xs text-muted-foreground mt-1">
          {eventsKpi?.p95LatencyMs != null
            ? "95th percentile delivery time"
            : "No delivery latency data"}
        </p>
      </Deferred>
    </Card.Content>
  </Card.Root>

  <Card.Root class="shadow-none py-4 gap-2">
    <Card.Header
      class="flex flex-row items-center justify-between pb-1 space-y-0"
    >
      <Card.Title
        class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
      >
        Subscriptions
      </Card.Title>
      <div class="rounded-md bg-muted/60 p-1.5 text-muted-foreground">
        <WebhookIcon class="size-4" />
      </div>
    </Card.Header>
    <Card.Content class="pt-0">
      <Deferred data="subscriptionsCount">
        {#snippet fallback()}
          <div class="space-y-1.5">
            <Skeleton class="h-8 w-24" />
            <Skeleton class="h-3.5 w-28" />
          </div>
        {/snippet}
        <div class="text-2xl lg:text-3xl font-bold tracking-tight">
          {subscriptionsCount != null
            ? subscriptionsCount.toLocaleString()
            : "0"}
        </div>
        <p class="text-xs text-muted-foreground mt-1">
          Active endpoint subscriptions
        </p>
      </Deferred>
    </Card.Content>
  </Card.Root>
</div>
