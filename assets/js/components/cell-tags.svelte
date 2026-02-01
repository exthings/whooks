<script lang="ts">
  let { tags }: { tags: string[] } = $props();
</script>

<div class="flex gap-1">
  {#each tags as tag (tag)}
    <span
      class="inline-flex items-center rounded-md bg-muted px-2 py-1 text-[0.625rem] text-muted-foreground font-mono"
    >
      {tag}
    </span>
  {/each}
</div>
