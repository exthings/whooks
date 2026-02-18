<script lang="ts">
  import { EyeIcon, EyeOffIcon } from "lucide-svelte";
  import CopyClipboard from "./copy-clipboard.svelte";
  let { value }: { value: string } = $props();

  let show = $state(false);
</script>

{#if show}
  <div class="flex items-center gap-2">
    <span class="font-mono text-xs">{value}</span>
    <CopyClipboard {value} />
  </div>
{:else}
  <div class="flex items-center gap-2">
    <span class="font-mono text-xs">••••••••••••</span>
    <button onclick={() => (show = true)}><EyeIcon size={18} /></button>
  </div>
{/if}
