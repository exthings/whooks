<script lang="ts">
  import type { Analytics } from "$types";
  import { scaleBand, scaleUtc, scaleTime } from "d3-scale";
  import { BarChart, type ChartContextValue, Highlight } from "layerchart";
  import * as Chart from "$lib/components/ui/chart/index.js";
  import { cubicInOut } from "svelte/easing";

  type Props = {
    data: Analytics[];
    interval: "minute" | "hour" | "day";
  };

  const { data, interval = "hour" }: Props = $props();

  const chartData = data
    .filter((item) => item.status === "success")
    .map((item) => ({
      date: new Date(item.dateTime),
      value: item.count,
    }));

  const chartConfig = {
    success: { label: "success", color: "var(--color-green-400)" },
  } satisfies Chart.ChartConfig;

  let context = $state<ChartContextValue>();

  let labelFormat: Intl.DateTimeFormatOptions = $derived.by(() => {
    switch (interval) {
      case "minute":
        return {
          hour: "2-digit",
          minute: "2-digit",
        };
      case "hour":
        return { day: "2-digit", hour: "2-digit", minute: "2-digit" };
      default:
        return { day: "2-digit", month: "2-digit" };
    }
  });

  $inspect(chartData);
</script>

<Chart.Container config={chartConfig} class="h-full w-full pl-2 pr-2 pb-0 pt-2">
  <BarChart
    bind:context
    x="date"
    y="value"
    series={[
      {
        key: "success",
        label: "Success",
        color: chartConfig.success.color,
        data: chartData,
      },
    ]}
    props={{
      bars: {
        stroke: "none",
        rounded: "none",
        // use the height of the chart to animate the bars
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
          return d.toLocaleDateString("en-US", labelFormat);
        },
        ticks: Math.floor(chartData.length / 6),
      },
    }}
  >
    {#snippet belowMarks()}
      <Highlight area={{ class: "fill-muted" }} />
    {/snippet}
    {#snippet tooltip()}
      <Chart.Tooltip
        nameKey="views"
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
