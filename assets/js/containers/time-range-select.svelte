<script lang="ts" module>
  export {
    type TimeRangeOption,
    TIME_RANGE_OPTIONS,
  } from "$components/metrics-range-select.svelte";

  import type { Interval, Last } from "$types";

  export const LAST_TO_INTERVAL: Record<Last, Interval> = {
    "1m": "minute",
    "1h": "minute",
    "12h": "hour",
    "24h": "hour",
    "48h": "hour",
    "1w": "day",
    "1mo": "day",
  };
</script>

<script lang="ts">
  import TimeRangeSelect, {
    type TimeRangeOption,
    TIME_RANGE_OPTIONS,
  } from "$components/metrics-range-select.svelte";
  import { router, page } from "@inertiajs/svelte";

  type Props = {
    propKey?: string;
    value?: Last;
    options?: TimeRangeOption[];
    placeholder?: string;
    disabled?: boolean;
    name?: string;
    only?: string[];
    onValueChange?: (value: Last, interval: Interval) => void;
  };

  let {
    propKey,
    value = $bindable(),
    options = TIME_RANGE_OPTIONS,
    placeholder = "Interval",
    disabled = false,
    name = "metricsRange",
    only,
    onValueChange,
  }: Props = $props();

  let selectedValue = $state<Last | undefined>(value);

  $effect(() => {
    if (value !== undefined) {
      selectedValue = value;
    }
  });

  $effect(() => {
    if (propKey) {
      const pageMetrics = $page.props[propKey] as { last?: Last } | undefined;
      if (pageMetrics?.last) {
        selectedValue = pageMetrics.last;
      }
    } else {
      selectedValue = $page.props["last"];
    }
  });

  const handleLastChange = (value: string) => {
    const last = value as Last;
    const interval = LAST_TO_INTERVAL[last] ?? "hour";
    selectedValue = last;
    value = last;

    if (propKey) {
      router.reload({
        data: { [propKey]: { last, interval } },
        only: only,
      });
    } else {
      router.reload({
        only: only,
        data: {
          last,
          interval,
        },
      });
    }

    onValueChange?.(last, interval);
  };
</script>

<TimeRangeSelect
  name="last"
  bind:value={selectedValue}
  placeholder="Interval"
  onValueChange={handleLastChange}
/>
