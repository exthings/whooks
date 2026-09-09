<script lang="ts">
  import type { Endpoint } from "$types";
  import Section from "$components/section.svelte";
  import EndpointsTable from "./endpoints-table.svelte";

  type Props = {
    endpoints?: Endpoint[];
  };

  const { endpoints }: Props = $props();
</script>

<Section title="Endpoints">
  <div>
    {#if endpoints}
      <EndpointsTable {endpoints} />
    {:else}
      <p class="text-sm text-muted-foreground">No endpoints found</p>
    {/if}
  </div>
</Section>
