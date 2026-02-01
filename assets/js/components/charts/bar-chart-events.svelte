<script lang="ts">
  import { scaleBand, scaleUtc } from "d3-scale";
  import { BarChart, type ChartContextValue } from "layerchart";
  import * as Chart from "$lib/components/ui/chart/index.js";
  import { cubicInOut } from "svelte/easing";

  const successData = [
    ...Array.from({ length: 50 }, (_, i) => ({
      date: new Date(2026, 1, 1, 12, 0, i),
      value: Math.floor(Math.random() * 200),
    })),
  ];

  const failedData = [
    ...Array.from({ length: 50 }, (_, i) => ({
      date: new Date(2026, 1, 1, 12, 0, i),
      value: Math.floor(Math.random() * 100),
    })),
  ];

  const chartConfig = {
    success: { label: "success", color: "var(--color-green-400)" },
    failed: { label: "failed", color: "var(--color-red-400)" },
  } satisfies Chart.ChartConfig;

  let context = $state<ChartContextValue>();
</script>

<div class="h-full">
  <BarChart
    bind:context
    grid={true}
    rule={false}
    legend={false}
    xScale={scaleBand().padding(0.25)}
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
    ]}
    seriesLayout="group"
    props={{
      bars: {
        stroke: "none",
        strokeWidth: 0,
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
          return d.toLocaleTimeString("en-US", {
            minute: "2-digit",
            second: "2-digit",
          });
        },
        ticks: (scale) => scaleUtc(scale.domain(), scale.range()).ticks(),
      },
      yAxis: { format: (d) => d },
    }}
  ></BarChart>
</div>
