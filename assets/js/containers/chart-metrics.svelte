<script lang="ts">
  import type { Analytics } from "$types";
  import type { Interval, Last } from "$types";

  import { Deferred, page } from "@inertiajs/svelte";
  import * as Card from "$lib/components/ui/card";
  import * as Empty from "$lib/components/ui/empty";
  import { BarChartEvents } from "$components/charts";
  import { Skeleton } from "$lib/components/ui/skeleton";
  import Section from "$components/section.svelte";
  import { ChartColumnIcon } from "lucide-svelte";

  type Props = {
    propKey?: string;
    title?: string;
  };

  const { propKey = "eventsMetrics", title }: Props = $props();

  let metrics:
    | { data: Analytics[]; interval: Interval; last: Last }
    | undefined = $derived.by(() => $page.props[propKey]);

  const hasData = $derived(
    Boolean(
      metrics?.data &&
        metrics.data.length > 0 &&
        metrics.data.some((item) => item.count > 0),
    ),
  );
</script>

<Section {title}>
  <Card.Root class="shadow-none gap-1 h-72">
    <Card.Content class="px-6">
      <div class="h-60">
        <Deferred data={propKey}>
          {#snippet fallback()}
            <Skeleton class="h-full w-full" />
          {/snippet}
          {#if hasData && metrics}
            <BarChartEvents data={metrics.data} interval={metrics.interval} />
          {:else}
            <Empty.Root
              class="h-full border border-dashed border-border/80 bg-muted/10 rounded-lg p-6 flex flex-col items-center justify-center text-center"
            >
              <Empty.Header class="gap-1.5 max-w-sm">
                <Empty.Media
                  variant="icon"
                  class="size-10 rounded-full bg-muted/80 text-muted-foreground ring-4 ring-muted/30 mb-1"
                >
                  <ChartColumnIcon class="size-5" />
                </Empty.Media>
                <Empty.Title class="text-sm font-semibold text-foreground">
                  No event metrics
                </Empty.Title>
                <Empty.Description
                  class="text-xs text-muted-foreground text-balance"
                >
                  {#if metrics?.last}
                    No events were recorded in the last {metrics.last}.
                  {:else}
                    No events were recorded for the selected time range.
                  {/if}
                  Delivery activity will appear here once webhooks are dispatched.
                </Empty.Description>
              </Empty.Header>
            </Empty.Root>
          {/if}
        </Deferred>
      </div>
    </Card.Content>
  </Card.Root>
</Section>
