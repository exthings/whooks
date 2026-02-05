<script lang="ts">
  import type { Analytics } from "$types";

  import { router, Deferred, page } from "@inertiajs/svelte";
  import * as Card from "$lib/components/ui/card";
  import { BarChartEvents } from "$components/charts";
  import * as Select from "$lib/components/ui/select";
  import { Skeleton } from "$lib/components/ui/skeleton";
  import Section from "$components/section.svelte";

  type Interval = "minute" | "hour" | "day";
  type Last = "1m" | "1h" | "12h" | "24h" | "48h" | "1w" | "1mo";

  type Props = {
    propKey?: string;
  };

  const { propKey = "eventsMetrics" }: Props = $props();

  let metrics: { data: Analytics[]; interval: Interval; last: Last } =
    $derived.by(() => $page.props[propKey]);

  const metricsRange = [
    { value: "1h", label: "1h" },
    { value: "12h", label: "12h" },
    { value: "24h", label: "24h" },
    { value: "48h", label: "48h" },
    { value: "1w", label: "1w" },
    { value: "1mo", label: "1mo" },
  ];

  const lastToInterval: Record<Last, Interval> = {
    "1m": "minute",
    "1h": "minute",
    "12h": "hour",
    "24h": "hour",
    "48h": "hour",
    "1w": "day",
    "1mo": "day",
  };

  let metricsRangeValue = $state();

  const metricsRangeContent = $derived(
    metricsRange.find((f) => f.value === metricsRangeValue)?.label ??
      "Interval",
  );

  const handleLastChange = (value: string) => {
    router.get(
      "",
      {
        [propKey]: { last: value, interval: lastToInterval[value as Last] },
        only: [propKey],
      },
      {
        preserveState: true,
        preserveScroll: true,
      },
    );
  };

  $effect(() => {
    if (metrics?.last) metricsRangeValue = metrics.last;
  });
</script>

{#snippet actions()}
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
{/snippet}

<Section title="Metrics" {actions}>
  <Card.Root class="shadow-none py-4 gap-1 h-72">
    <Card.Content>
      <div class="h-60">
        <Deferred data={propKey}>
          {#snippet fallback()}
            <Skeleton class="h-full w-full" />
          {/snippet}
          {#if metrics?.data.length > 0}
            <BarChartEvents data={metrics.data} interval={metrics.interval} />
          {:else}
            <p>No data available</p>
          {/if}
        </Deferred>
      </div>
    </Card.Content>
  </Card.Root>
</Section>
