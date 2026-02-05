<script lang="ts">
  import type { Snippet } from "svelte";

  type Props = {
    title: string;
    description?: string;
    actions?: Snippet;
    children?: Snippet;
  };

  const { title, description, actions, children }: Props = $props();
</script>

<div>
  <div class="flex items-center justify-between pb-2 min-h-12">
    <h2 class="font-semibold">{title}</h2>
    {#if actions}
      <div>{@render actions()}</div>
    {/if}
  </div>
  {@render children?.()}
</div>
