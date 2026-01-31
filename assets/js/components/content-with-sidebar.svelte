<script lang="ts">
  import type { Snippet } from "svelte";

  type Props = {
    sidebar?: Snippet;
    children: Snippet;
  };

  let { sidebar, children }: Props = $props();
</script>

<div class="flex overflow-hidden h-[calc(100vh-1rem)]">
  {#if sidebar}
    <div
      class="flex flex-col overflow-hidden border-r border-gray-200 min-w-[320px]"
    >
      {@render sidebar()}
    </div>
  {/if}

  {@render children()}
</div>
