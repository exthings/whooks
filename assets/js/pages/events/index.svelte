<script lang="ts">
  import type { Event, Meta } from "$types";

  import SidebarHeader from "$components/sidebar-header.svelte";
  import ContentWithSidebar from "$components/content-with-sidebar.svelte";
  import { EventsTable } from "$containers";
  import Filters from "./containers/filters.svelte";

  type Props = {
    events: { data: Event[]; meta: Meta };
  };

  const { events }: Props = $props();
</script>

<svelte:head>
  <title>Events</title>
</svelte:head>

{#snippet sidebar()}
  <SidebarHeader title="Events" />
  <div class="px-6 py-4">
    <Filters />
  </div>
{/snippet}

<ContentWithSidebar {sidebar}>
  <div class="px-6 py-4 flex-1 flex flex-col gap-6 overflow-x-scroll">
    <EventsTable
      propsKey="events"
      columnVisibility={[
        "insertedAt",
        "id",
        "consumer",
        "topic",
        "status",
        "tags",
      ]}
    />
  </div>
</ContentWithSidebar>
