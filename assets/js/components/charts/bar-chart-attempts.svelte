<script lang="ts">
  import type { Analytics } from "$types";
  import { scaleBand, scaleSymlog } from "d3-scale";
  import {
    BarChart,
    type ChartContextValue,
    Highlight,
    Text,
  } from "layerchart";
  import * as Chart from "$lib/components/ui/chart/index.js";
  import { cubicInOut } from "svelte/easing";

  type Props = {
    data: Analytics[];
    interval: "minute" | "hour" | "day" | string;
  };

  const { data, interval = "hour" }: Props = $props();

  const mapFn = (item: Analytics) => ({
    date: new Date(item.dateTime),
    value: item.count,
  });

  const successData = $derived(
    data.filter((item) => item.status === "success").map(mapFn),
  );
  const failedData = $derived(
    data.filter((item) => item.status === "failed").map(mapFn),
  );
  const retryData = $derived(
    data.filter((item) => item.status === "retry").map(mapFn),
  );
  const processingData = $derived(
    data.filter((item) => item.status === "processing").map(mapFn),
  );
  const scheduledData = $derived(
    data.filter((item) => item.status === "scheduled").map(mapFn),
  );
  const discardedData = $derived(
    data.filter((item) => item.status === "discarded").map(mapFn),
  );

  const chartConfig = {
    success: { label: "Success", color: "var(--color-emerald-500)" },
    failed: { label: "Failed", color: "var(--color-red-500)" },
    retry: { label: "Retry", color: "var(--color-amber-500)" },
    processing: { label: "Processing", color: "var(--color-blue-500)" },
    scheduled: { label: "Scheduled", color: "var(--color-slate-400)" },
    discarded: { label: "Discarded", color: "var(--color-purple-400)" },
  } satisfies Chart.ChartConfig;

  let context = $state<ChartContextValue>();

  let labelFormat: Intl.DateTimeFormatOptions = $derived.by(() => {
    switch (interval) {
      case "minute":
        return {
          hour: "numeric",
          minute: "2-digit",
        };
      case "hour":
        return { day: "2-digit", hour: "2-digit", minute: "2-digit" };
      default:
        return { day: "2-digit", month: "2-digit" };
    }
  });

  const formatter = $derived(new Intl.DateTimeFormat("en-US", labelFormat));
</script>

{#snippet tickLabel({ props, index }: { props: any; index: number })}
  {#if index > 0}
    <Text {...props} dy={16} textAnchor={index ? "end" : "start"} />
  {/if}
{/snippet}

<Chart.Container config={chartConfig} class="h-full w-full pl-0 pr-0 pb-0 pt-2">
  <BarChart
    bind:context
    x="date"
    y="value"
    series={[
      {
        key: "success",
        label: "Success",
        color: chartConfig.success.color,
        data: successData,
      },
      {
        key: "failed",
        label: "Failed",
        color: chartConfig.failed.color,
        data: failedData,
      },
      {
        key: "retry",
        label: "Retry",
        color: chartConfig.retry.color,
        data: retryData,
      },
      {
        key: "processing",
        label: "Processing",
        color: chartConfig.processing.color,
        data: processingData,
      },
      {
        key: "scheduled",
        label: "Scheduled",
        color: chartConfig.scheduled.color,
        data: scheduledData,
      },
      {
        key: "discarded",
        label: "Discarded",
        color: chartConfig.discarded.color,
        data: discardedData,
      },
    ]}
    xScale={scaleBand().padding(0.25)}
    yScale={scaleSymlog()}
    yDomain={[0, null]}
    seriesLayout="stack"
    props={{
      bars: {
        stroke: "none",
        rounded: "none",
        initialY: context?.height,
        initialHeight: 0,
        motion: {
          y: { type: "tween", duration: 500, easing: cubicInOut },
          height: { type: "tween", duration: 500, easing: cubicInOut },
        },
      },
      highlight: { area: { fill: "none" } },
      xAxis: {
        format: (d: Date) => {
          return formatter.format(d);
        },
        tickOcclusion: {
          padding: 40,
          priority: "start",
        },
        tickLabelProps: {
          dy: 10,
        },
        tickLabel,
        labelPlacement: "end",
        placement: "bottom",
      },
    }}
  >
    {#snippet belowMarks()}
      <Highlight area={{ class: "fill-muted" }} />
    {/snippet}
    {#snippet tooltip()}
      <Chart.Tooltip
        nameKey="value"
        labelFormatter={(v: Date) => {
          return v.toLocaleDateString("en-US", {
            month: "short",
            day: "numeric",
            year: "numeric",
            hour: "2-digit",
            minute: "2-digit",
            second: "2-digit",
          });
        }}
      />
    {/snippet}
  </BarChart>
</Chart.Container>
