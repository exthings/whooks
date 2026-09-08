<script lang="ts" module>
  import type { Interval, Last } from "$types";

  export type TimeRangeOption = {
    value: Last;
    label: string;
  };

  export const TIME_RANGE_OPTIONS: TimeRangeOption[] = [
    { value: "1h", label: "1h" },
    { value: "12h", label: "12h" },
    { value: "24h", label: "24h" },
    { value: "48h", label: "48h" },
    { value: "1w", label: "1w" },
    { value: "1mo", label: "1mo" },
  ];

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
  import * as Select from "$lib/components/ui/select";
  import { cn } from "$lib/utils";

  type Props = {
    name: string;
    value?: Last;
    placeholder?: string;
    disabled?: boolean;
    onValueChange?: (value: string) => void;
  };

  let {
    name,
    value = $bindable(),
    placeholder = "Interval",
    disabled = false,
    onValueChange,
  }: Props = $props();

  let selectedValue = $state<string | undefined>(value);

  $effect(() => {
    if (value !== undefined) {
      selectedValue = value;
    }
  });

  const selectedContent = $derived(
    TIME_RANGE_OPTIONS.find((f) => f.value === selectedValue)?.label ??
      placeholder,
  );

  const handleLastChange = (value: string) => {
    onValueChange?.(value as Last);
  };
</script>

<Select.Root
  type="single"
  {name}
  {disabled}
  bind:value={selectedValue}
  onValueChange={handleLastChange}
>
  <Select.Trigger class={cn("w-24")} size="sm">
    {selectedContent}
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
