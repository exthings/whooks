<script lang="ts" module>
  import type { Interval, Last } from "$types";

  export type TimeRangeOption = {
    value: Last;
    label: string;
    interval: Interval[];
  };

  export const TIME_RANGE_OPTIONS: TimeRangeOption[] = [
    { value: "1h", label: "1h", interval: ["15s", "30s", "45s", "1m"] },
    {
      value: "12h",
      label: "12h",
      interval: ["15m", "30m", "45m", "1h"],
    },
    {
      value: "24h",
      label: "24h",
      interval: ["15m", "30m", "45m", "1h"],
    },
    {
      value: "48h",
      label: "48h",
      interval: ["30m", "45m", "1h"],
    },
    {
      value: "1w",
      label: "1w",
      interval: ["1h", "1d"],
    },
    {
      value: "1mo",
      label: "1mo",
      interval: ["1d"],
    },
  ];
</script>

<script lang="ts">
  import * as Select from "$lib/components/ui/select";
  import * as ToggleGroup from "$lib/components/ui/toggle-group";
  import { cn } from "$lib/utils";

  type Props = {
    name: string;
    last: Last;
    interval: Interval;
    placeholder?: string;
    disabled?: boolean;
    onValueChange?: (last: Last, interval: Interval) => void;
  };

  let {
    name,
    last = $bindable(),
    interval = $bindable(),
    placeholder = "Interval",
    disabled = false,
    onValueChange,
  }: Props = $props();

  let context: TimeRangeOption | undefined = $state();

  const handleLastChange = (value: string) => {
    last = value as Last;
    context = TIME_RANGE_OPTIONS.find((f) => f.value === last);
    interval = context?.interval[0] ?? interval;
    onValueChange?.(last, interval);
  };

  const handleIntervalChange = (value: string) => {
    interval = value as Interval;
    onValueChange?.(last, interval);
  };

  $effect(() => {
    if (!context && last) {
      context = TIME_RANGE_OPTIONS.find((f) => f.value === last);
    }
  });
</script>

<Select.Root
  type="single"
  {name}
  {disabled}
  value={last}
  onValueChange={handleLastChange}
>
  <Select.Trigger class={cn("w-24")} size="sm">
    {context?.label ?? placeholder}
  </Select.Trigger>
  <Select.Content>
    <Select.Group>
      {#each TIME_RANGE_OPTIONS as range (range.value)}
        <Select.Item value={range.value} label={range.label}>
          {range.label}
        </Select.Item>
      {/each}
    </Select.Group>
  </Select.Content>
</Select.Root>

<ToggleGroup.Root
  variant="outline"
  size="sm"
  type="single"
  value={interval}
  onValueChange={handleIntervalChange}
>
  {#each context?.interval as interval (interval)}
    <ToggleGroup.Item value={interval} aria-label={interval}>
      {interval}
    </ToggleGroup.Item>
  {/each}
</ToggleGroup.Root>
