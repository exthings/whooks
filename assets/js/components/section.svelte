<script lang="ts">
  import type { Snippet } from "svelte";
  import { cn } from "$lib/utils";

  type Props = {
    title?: string;
    description?: string;
    actions?: Snippet;
    children?: Snippet;
  };

  const { title, description, actions, children }: Props = $props();
</script>

<div>
  {#if title || actions}
    <div class="flex items-center justify-between pb-2 min-h-12">
      {#if title}
        <h2 class="font-semibold">{title}</h2>
      {/if}
      {#if actions}
        <div>{@render actions()}</div>
      {/if}
    </div>
  {/if}
  {@render children?.()}
</div>
