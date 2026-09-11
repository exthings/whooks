<script lang="ts">
  import * as DropdownMenu from "$lib/components/ui/dropdown-menu";
  import { Button } from "$lib/components/ui/button";
  import {
    ChevronDownIcon,
    RotateCcwIcon,
    HistoryIcon,
    SendIcon,
  } from "lucide-svelte";

  type Props = {
    showReplayMissing?: boolean;
    onRecoverFailed: () => void;
    onReplayMissing?: () => void;
    onBulkReplay: () => void;
  };

  const {
    showReplayMissing = false,
    onRecoverFailed,
    onReplayMissing,
    onBulkReplay,
  }: Props = $props();
</script>

<DropdownMenu.Root>
  <DropdownMenu.Trigger>
    <Button variant="outline" size="sm" class="gap-1.5 font-medium">
      <RotateCcwIcon class="size-3.5" />
      <span>Resend</span>
      <ChevronDownIcon class="size-3.5 opacity-60" />
    </Button>
  </DropdownMenu.Trigger>
  <DropdownMenu.Content align="end" class="w-56">
    <DropdownMenu.Item onclick={onRecoverFailed} class="cursor-pointer">
      <RotateCcwIcon class="mr-2 size-4 text-muted-foreground" />
      <span>Failed events</span>
    </DropdownMenu.Item>
    {#if showReplayMissing && onReplayMissing}
      <DropdownMenu.Item onclick={onReplayMissing} class="cursor-pointer">
        <HistoryIcon class="mr-2 size-4 text-muted-foreground" />
        <span>Missing events</span>
      </DropdownMenu.Item>
    {/if}
    <DropdownMenu.Item onclick={onBulkReplay} class="cursor-pointer">
      <SendIcon class="mr-2 size-4 text-muted-foreground" />
      <span>Bulk</span>
    </DropdownMenu.Item>
  </DropdownMenu.Content>
</DropdownMenu.Root>
