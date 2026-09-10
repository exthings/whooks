<script lang="ts">
  import type { Last } from "$types";
  import * as ToggleGroup from "$lib/components/ui/toggle-group";

  const lastOptions = ["1h", "12h", "24h", "48h", "1w", "1mo"] as Last[];

  type Props = {
    value?: Last | string;
    disabled?: boolean;
    onValueChange?: (value: string) => void;
  };

  let { value = "", disabled = false, onValueChange }: Props = $props();
</script>

<ToggleGroup.Root
  variant="outline"
  size="sm"
  type="single"
  value={disabled ? "" : value}
  class="w-full"
  onValueChange={(val) => onValueChange?.(val)}
>
  {#each lastOptions as option (option)}
    <ToggleGroup.Item value={option} aria-label={option}>
      {option}
    </ToggleGroup.Item>
  {/each}
</ToggleGroup.Root>
