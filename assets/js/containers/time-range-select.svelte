<script lang="ts" module>
  export {
    type TimeRangeOption,
    TIME_RANGE_OPTIONS,
  } from "$components/metrics-range-select.svelte";

  import type { Interval, Last } from "$types";
</script>

<script lang="ts">
  import TimeRangeSelect, {
    type TimeRangeOption,
    TIME_RANGE_OPTIONS,
  } from "$components/metrics-range-select.svelte";
  import { router, page } from "@inertiajs/svelte";

  type Props = {
    propKey?: string;
    last?: Last;
    interval?: Interval;
    options?: TimeRangeOption[];
    placeholder?: string;
    disabled?: boolean;
    name?: string;
    only?: string[];
    onValueChange?: (value: Last, interval: Interval) => void;
  };

  let {
    propKey,
    last = $bindable(),
    interval = $bindable(),
    options = TIME_RANGE_OPTIONS,
    placeholder = "Interval",
    disabled = false,
    name = "metricsRange",
    only,
    onValueChange,
  }: Props = $props();

  $effect(() => {
    if (propKey) {
      const pageMetrics = $page.props[propKey] as { last?: Last } | undefined;
      if (pageMetrics?.last) {
        last = pageMetrics.last;
      }
    } else {
      last = $page.props["globalFilters"]["last"];
      interval = $page.props["globalFilters"]["interval"];
    }
  });

  const handleLastChange = (last: Last, interval: Interval) => {
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

  $inspect(last);
</script>

<TimeRangeSelect
  name="last"
  bind:last
  bind:interval
  placeholder="Interval"
  onValueChange={handleLastChange}
/>
