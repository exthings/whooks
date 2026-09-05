<script lang="ts">
  import type { Snippet } from "svelte";
  import { Label } from "$lib/components/ui/label";
  import { ChevronDownIcon, ChevronUpIcon, XIcon } from "lucide-svelte";
  import * as Collapsible from "$lib/components/ui/collapsible";
  import { Badge } from "$lib/components/ui/badge";

  type Props = {
    children: Snippet;
    label: string;
    count?: number;
    onClear?: () => void;
  };

  let { children, label, count = $bindable(), onClear }: Props = $props();

  let open = $state(false);
</script>

<Collapsible.Root class="space-y-2" bind:open>
  <Collapsible.Trigger
    class="w-full flex items-center justify-between gap-2 text-sm"
  >
    <Label>
      {label}
    </Label>
    <div class="flex items-center gap-2">
      {#if count}
        <button
          class="flex items-center gap-0.5 z-50 hover:bg-gray-100 border rounded-md px-1.5"
          onclick={(e) => {
            e.stopPropagation();
            onClear?.();
          }}
          type="button"
        >
          <span class="text-xs font-mono">{count}</span>
          <XIcon size={14} />
        </button>
      {/if}
      {#if open}
        <ChevronUpIcon size={18} />
      {:else}
        <ChevronDownIcon size={18} />
      {/if}
      <span class="sr-only">Toggle</span>
    </div>
  </Collapsible.Trigger>

  <Collapsible.Content class="space-y-2">
    {@render children()}
  </Collapsible.Content>
</Collapsible.Root>
