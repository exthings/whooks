<script lang="ts">
  import type { EventsKpi, AttemptsKpi, GlobalFilters } from "$types";
  import { Deferred, page } from "@inertiajs/svelte";
  import * as Card from "$lib/components/ui/card";
  import BadgeStatus from "$components/badge-status.svelte";
  import Skeleton from "$lib/components/ui/skeleton/skeleton.svelte";
  import { getSuccessRateLabel } from "$common";
  import {
    ActivityIcon,
    CircleCheckIcon,
    AlertCircleIcon,
    ClockIcon,
    SendIcon,
    CheckCheckIcon,
    XCircleIcon,
    TimerIcon,
    WebhookIcon,
  } from "lucide-svelte";

  type Props = {
    eventsKpi?: EventsKpi;
    attemptsKpi?: AttemptsKpi;
    subscriptionsCount?: number;
    globalFilters?: GlobalFilters;
  };

  const {
    eventsKpi,
    attemptsKpi,
    subscriptionsCount = 0,
    globalFilters,
  }: Props = $props();

  const currentGlobalFilters = $derived(
    globalFilters ??
      ($page?.props?.globalFilters as GlobalFilters | undefined) ?? {
        last: "24h",
        interval: "1h",
      },
  );

  const rangeSeconds = $derived.by(() => {
    const last = currentGlobalFilters?.last;
    switch (last) {
      case "1m":
        return 60;
      case "1h":
        return 3600;
      case "12h":
        return 12 * 3600;
      case "24h":
        return 24 * 3600;
      case "48h":
        return 48 * 3600;
      case "1w":
        return 7 * 86400;
      case "1mo":
        return 30 * 86400;
      default:
        return 86400;
    }
  });

  const avgEventsPerSec = $derived(
    eventsKpi?.totalCount != null && rangeSeconds > 0
      ? eventsKpi.totalCount / rangeSeconds
      : null,
  );

  const avgAttemptsPerSec = $derived(
    attemptsKpi?.totalAttempts != null && rangeSeconds > 0
      ? attemptsKpi.totalAttempts / rangeSeconds
      : null,
  );

  function formatPerSecond(rate: number | null): string {
    if (rate == null || rate === 0) return "0/s";
    if (rate < 0.01) return "<0.01/s";
    return `${Math.round(rate).toLocaleString()}/s`;
  }

  const successRateLabel = $derived(
    attemptsKpi?.successRate != null
      ? getSuccessRateLabel(attemptsKpi.successRate)
      : null,
  );
</script>

<Card.Root class="shadow-none py-0 gap-0 divide-y divide-border">
  <!-- Events Row -->
  <div
    class="grid grid-cols-1 divide-y divide-border lg:grid-cols-4 lg:divide-y-0 lg:divide-x"
  >
    <!-- Item 1: Total Events -->
    <div class="p-6 flex flex-col gap-2">
      <div class="flex flex-row items-center justify-between pb-1 space-y-0">
        <span
          class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
        >
          Total Events
        </span>
        <div class="rounded-md bg-muted/60 p-1.5 text-muted-foreground">
          <ActivityIcon class="size-4" />
        </div>
      </div>
      <div>
        <Deferred data="eventsKpi">
          {#snippet fallback()}
            <div class="space-y-1.5">
              <Skeleton class="h-8 w-24" />
              <Skeleton class="h-3.5 w-32" />
            </div>
          {/snippet}
          <div
            class="text-2xl lg:text-3xl font-bold tracking-tight flex items-baseline gap-2"
          >
            <span>
              {eventsKpi?.totalCount != null
                ? eventsKpi.totalCount.toLocaleString()
                : "0"}
            </span>
            {#if avgEventsPerSec != null}
              <span class="text-xs font-normal text-muted-foreground">
                (~{formatPerSecond(avgEventsPerSec)})
              </span>
            {/if}
          </div>
          <p
            class="text-xs text-muted-foreground mt-1 flex items-center gap-1.5"
          >
            <span
              class="inline-flex items-center gap-1 font-medium text-foreground"
            >
              <WebhookIcon class="size-3 text-muted-foreground" />
              {subscriptionsCount.toLocaleString()}
              {subscriptionsCount === 1 ? "subscription" : "subscriptions"}
            </span>
          </p>
        </Deferred>
      </div>
    </div>

    <!-- Item 2: Processed Events -->
    <div class="p-6 flex flex-col gap-2">
      <div class="flex flex-row items-center justify-between pb-1 space-y-0">
        <span
          class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
        >
          Processed Events
        </span>
        <div
          class="rounded-md bg-emerald-500/10 p-1.5 text-emerald-600 dark:text-emerald-400"
        >
          <CircleCheckIcon class="size-4" />
        </div>
      </div>
      <div>
        <Deferred data="eventsKpi">
          {#snippet fallback()}
            <div class="space-y-1.5">
              <Skeleton class="h-8 w-24" />
              <Skeleton class="h-3.5 w-28" />
            </div>
          {/snippet}
          <div
            class="text-2xl lg:text-3xl font-bold tracking-tight text-emerald-600 dark:text-emerald-400"
          >
            {eventsKpi?.processedCount != null
              ? eventsKpi.processedCount.toLocaleString()
              : "0"}
          </div>
          <p class="text-xs text-muted-foreground mt-1">
            {#if eventsKpi?.totalCount && eventsKpi.totalCount > 0}
              {Math.round(
                (eventsKpi.processedCount / eventsKpi.totalCount) * 100,
              )}% completion rate
            {:else}
              Processed events
            {/if}
          </p>
        </Deferred>
      </div>
    </div>

    <!-- Item 3: Pending & Processing Events -->
    <div class="p-6 flex flex-col gap-2">
      <div class="flex flex-row items-center justify-between pb-1 space-y-0">
        <span
          class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
        >
          Pending & Processing Events
        </span>
        <div
          class="rounded-md bg-amber-500/10 p-1.5 text-amber-600 dark:text-amber-400"
        >
          <ClockIcon class="size-4" />
        </div>
      </div>
      <div>
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
            <span>
              {eventsKpi != null
                ? (
                    eventsKpi.pendingCount + eventsKpi.processingCount
                  ).toLocaleString()
                : "0"}
            </span>
            {#if (eventsKpi?.scheduledCount ?? 0) > 0}
              <span class="text-xs font-normal text-muted-foreground">
                ({eventsKpi?.scheduledCount} scheduled)
              </span>
            {/if}
          </div>
          <div
            class="text-xs text-muted-foreground mt-1 flex items-center gap-1.5"
          >
            <span class="text-amber-600 dark:text-amber-400 font-medium">
              {(eventsKpi?.pendingCount ?? 0).toLocaleString()} pending
            </span>
            <span>·</span>
            <span class="text-blue-600 dark:text-blue-400 font-medium">
              {(eventsKpi?.processingCount ?? 0).toLocaleString()} processing
            </span>
          </div>
        </Deferred>
      </div>
    </div>

    <!-- Item 4: Unprocessed Events -->
    <div class="p-6 flex flex-col gap-2">
      <div class="flex flex-row items-center justify-between pb-1 space-y-0">
        <span
          class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
        >
          Unprocessed Events
        </span>
        <div
          class="rounded-md bg-rose-500/10 p-1.5 text-rose-600 dark:text-rose-400"
        >
          <AlertCircleIcon class="size-4" />
        </div>
      </div>
      <div>
        <Deferred data="eventsKpi">
          {#snippet fallback()}
            <div class="space-y-1.5">
              <Skeleton class="h-8 w-24" />
              <Skeleton class="h-3.5 w-28" />
            </div>
          {/snippet}
          <div
            class="text-2xl lg:text-3xl font-bold tracking-tight {eventsKpi &&
            eventsKpi.unprocessedCount > 0
              ? 'text-rose-600 dark:text-rose-400'
              : ''}"
          >
            {eventsKpi?.unprocessedCount != null
              ? eventsKpi.unprocessedCount.toLocaleString()
              : "0"}
          </div>
          <p class="text-xs text-muted-foreground mt-1">
            {#if eventsKpi && eventsKpi.unprocessedCount > 0}
              <span class="font-medium text-rose-600 dark:text-rose-400"
                >Unrouted or unprocessed</span
              >
            {:else}
              No unprocessed events
            {/if}
          </p>
        </Deferred>
      </div>
    </div>
  </div>

  <!-- Delivery Attempts Row -->
  <div
    class="grid grid-cols-1 divide-y divide-border lg:grid-cols-4 lg:divide-y-0 lg:divide-x"
  >
    <!-- Item 1: Total Delivery Attempts & Rates -->
    <div class="p-6 flex flex-col gap-2">
      <div class="flex flex-row items-center justify-between pb-1 space-y-0">
        <span
          class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
        >
          Total Delivery Attempts
        </span>
        <div class="rounded-md bg-muted/60 p-1.5 text-muted-foreground">
          <SendIcon class="size-4" />
        </div>
      </div>
      <div>
        <Deferred data="attemptsKpi">
          {#snippet fallback()}
            <div class="space-y-1.5">
              <Skeleton class="h-8 w-24" />
              <Skeleton class="h-3.5 w-32" />
            </div>
          {/snippet}
          <div
            class="text-2xl lg:text-3xl font-bold tracking-tight flex items-baseline gap-2"
          >
            <span>
              {attemptsKpi?.totalAttempts != null
                ? attemptsKpi.totalAttempts.toLocaleString()
                : "0"}
            </span>
            {#if attemptsKpi?.successRate != null && successRateLabel}
              <BadgeStatus
                label={successRateLabel.label}
                variant={successRateLabel.variant}
              />
            {/if}
          </div>
          <p
            class="text-xs text-muted-foreground mt-1 flex items-center gap-1.5 flex-wrap"
          >
            {#if avgAttemptsPerSec != null}
              <span class="font-medium text-foreground">
                ~{formatPerSecond(avgAttemptsPerSec)}
              </span>
              <span>·</span>
            {/if}
            <span>
              {attemptsKpi?.successRate != null
                ? `${attemptsKpi.successRate}% overall success rate`
                : "No attempts recorded"}
            </span>
          </p>
        </Deferred>
      </div>
    </div>

    <!-- Item 2: Successful Attempts -->
    <div class="p-6 flex flex-col gap-2">
      <div class="flex flex-row items-center justify-between pb-1 space-y-0">
        <span
          class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
        >
          Successful Attempts
        </span>
        <div
          class="rounded-md bg-emerald-500/10 p-1.5 text-emerald-600 dark:text-emerald-400"
        >
          <CheckCheckIcon class="size-4" />
        </div>
      </div>
      <div>
        <Deferred data="attemptsKpi">
          {#snippet fallback()}
            <div class="space-y-1.5">
              <Skeleton class="h-8 w-24" />
              <Skeleton class="h-3.5 w-28" />
            </div>
          {/snippet}
          <div
            class="text-2xl lg:text-3xl font-bold tracking-tight text-emerald-600 dark:text-emerald-400"
          >
            {attemptsKpi?.successCount != null
              ? attemptsKpi.successCount.toLocaleString()
              : "0"}
          </div>
          <p class="text-xs text-muted-foreground mt-1">
            {#if (attemptsKpi?.processingCount ?? 0) > 0}
              <span class="font-medium text-blue-600 dark:text-blue-400">
                {attemptsKpi?.processingCount.toLocaleString()} processing
              </span>
            {:else}
              Successful deliveries
            {/if}
          </p>
        </Deferred>
      </div>
    </div>

    <!-- Item 3: Failed Attempts & Retries -->
    <div class="p-6 flex flex-col gap-2">
      <div class="flex flex-row items-center justify-between pb-1 space-y-0">
        <span
          class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
        >
          Failed Attempts & Retries
        </span>
        <div
          class="rounded-md bg-red-500/10 p-1.5 text-red-600 dark:text-red-400"
        >
          <XCircleIcon class="size-4" />
        </div>
      </div>
      <div>
        <Deferred data="attemptsKpi">
          {#snippet fallback()}
            <div class="space-y-1.5">
              <Skeleton class="h-8 w-24" />
              <Skeleton class="h-3.5 w-28" />
            </div>
          {/snippet}
          <div
            class="text-2xl lg:text-3xl font-bold tracking-tight {attemptsKpi &&
            attemptsKpi.failedCount > 0
              ? 'text-red-600 dark:text-red-400'
              : ''}"
          >
            {attemptsKpi?.failedCount != null
              ? attemptsKpi.failedCount.toLocaleString()
              : "0"}
          </div>
          <div
            class="text-xs text-muted-foreground mt-1 flex items-center gap-1.5"
          >
            <span class="text-amber-600 dark:text-amber-400 font-medium">
              {(attemptsKpi?.retryCount ?? 0).toLocaleString()} retrying
            </span>
            <span>·</span>
            <span class="text-muted-foreground">
              {(attemptsKpi?.discardedCount ?? 0).toLocaleString()} discarded
            </span>
          </div>
        </Deferred>
      </div>
    </div>

    <!-- Item 4: P95 Delivery Latency -->
    <div class="p-6 flex flex-col gap-2">
      <div class="flex flex-row items-center justify-between pb-1 space-y-0">
        <span
          class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
        >
          P95 Delivery Latency
        </span>
        <div
          class="rounded-md bg-purple-500/10 p-1.5 text-purple-600 dark:text-purple-400"
        >
          <TimerIcon class="size-4" />
        </div>
      </div>
      <div>
        <Deferred data="attemptsKpi">
          {#snippet fallback()}
            <div class="space-y-1.5">
              <Skeleton class="h-8 w-24" />
              <Skeleton class="h-3.5 w-28" />
            </div>
          {/snippet}
          <div
            class="text-2xl lg:text-3xl font-bold tracking-tight"
          >
            {attemptsKpi?.p95LatencyMs != null
              ? `${Math.round(attemptsKpi.p95LatencyMs)} ms`
              : "-"}
          </div>
          <p class="text-xs text-muted-foreground mt-1">
            {attemptsKpi?.p95LatencyMs != null
              ? "95th percentile delivery time"
              : "No delivery latency data"}
          </p>
        </Deferred>
      </div>
    </div>
  </div>
</Card.Root>
