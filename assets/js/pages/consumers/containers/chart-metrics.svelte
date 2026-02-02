<script lang="ts">
  import type { Analytics } from "$types";

  import { router, Deferred } from "@inertiajs/svelte";
  import * as Card from "$lib/components/ui/card";
  import { BarChartEvents } from "$components/charts";
  import * as Select from "$lib/components/ui/select";
  import { Skeleton } from "$lib/components/ui/skeleton";

  type Interval = "minute" | "hour" | "day";
  type Last = "1h" | "12h" | "24h" | "48h" | "1w" | "1m";

  type Props = {
    data?: Analytics[];
    interval?: Interval;
    last?: Last;
  };

  const { data = [], interval = "hour", last = "24h" }: Props = $props();

  const metricsRange = [
    { value: "1h", label: "1h" },
    { value: "12h", label: "12h" },
    { value: "24h", label: "24h" },
    { value: "48h", label: "48h" },
    { value: "1w", label: "1w" },
    { value: "1m", label: "1m" },
  ];

  const lastToInterval: Record<Last, Interval> = {
    "1h": "minute",
    "12h": "hour",
    "24h": "hour",
    "48h": "hour",
    "1w": "day",
    "1m": "day",
  };

  let metricsRangeValue = $state(last);

  const metricsRangeContent = $derived(
    metricsRange.find((f) => f.value === metricsRangeValue)?.label ??
      "Select a interval",
  );

  const handleLastChange = (value: string) => {
    router.get(
      "",
      {
        metrics: { last: value, interval: lastToInterval[value as Last] },
      },
      {
        preserveState: true,
        preserveScroll: true,
      },
    );
  };

  $inspect(data);
</script>

<div>
  <div class="flex items-center justify-between pb-2">
    <h2 class="font-semibold">Metrics</h2>
    <Select.Root
      type="single"
      name="metricsRange"
      bind:value={metricsRangeValue}
      onValueChange={handleLastChange}
    >
      <Select.Trigger class="w-24">
        {metricsRangeContent}
      </Select.Trigger>
      <Select.Content>
        <Select.Group>
          {#each metricsRange as range (range.value)}
            <Select.Item
              value={range.value}
              label={range.label}
              disabled={range.value === "grapes"}
            >
              {range.label}
            </Select.Item>
          {/each}
        </Select.Group>
      </Select.Content>
    </Select.Root>
  </div>
  <Card.Root class="shadow-none py-4 gap-1">
    <Card.Content>
      <div class="h-72">
        <Deferred data="eventsAnalytics">
          {#snippet fallback()}
            <Skeleton class="h-full w-full" />
          {/snippet}
          {#if data.length > 0}
            <BarChartEvents {data} {interval} />
          {:else}
            <p>No data available</p>
          {/if}
        </Deferred>
      </div>
    </Card.Content>
  </Card.Root>
</div>
