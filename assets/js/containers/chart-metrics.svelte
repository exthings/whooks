<script lang="ts">
  import type { Analytics } from "$types";

  import { Deferred, page } from "@inertiajs/svelte";
  import * as Card from "$lib/components/ui/card";
  import { BarChartEvents } from "$components/charts";
  import {
    type Interval,
    type Last,
  } from "$containers/time-range-select.svelte";
  import { Skeleton } from "$lib/components/ui/skeleton";
  import Section from "$components/section.svelte";

  type Props = {
    propKey?: string;
  };

  const { propKey = "eventsMetrics" }: Props = $props();

  let metrics: { data: Analytics[]; interval: Interval; last: Last } =
    $derived.by(() => $page.props[propKey]);
</script>

<Section>
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
