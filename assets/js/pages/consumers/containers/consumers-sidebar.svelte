<script lang="ts">
  import type { Consumer, Meta } from "$types";
  import SidebarHeader from "$components/sidebar-header.svelte";
  import SidebarItem from "$components/sidebar-item.svelte";
  import { Link, router } from "@inertiajs/svelte";
  import { buildHref, getFilterValue } from "$utils";
  import { cn } from "$lib/utils";
  import { useDebounce } from "runed";

  type Props = {
    consumers: { data: Consumer[]; meta: Meta };
    selectedId?: string | null;
    onCreate: () => void;
  };

  const { consumers, selectedId, onCreate }: Props = $props();

  const searchName = $derived(
    getFilterValue(consumers.meta.filters, "name")[0]?.value,
  );

  const handleSearch = useDebounce((e: Event) => {
    const target = e.target as HTMLInputElement;
    const searchValue = target.value;

    router.get(
      "",
      {
        filters: searchValue
          ? [
              {
                field: "name",
                op: "ilike",
                value: searchValue,
              },
            ]
          : [],
      },
      {
        queryStringArrayFormat: "indices",
        preserveState: true,
      },
    );
  }, 500);
</script>

<SidebarHeader
  title="Consumers"
  {onCreate}
  onSearch={handleSearch}
  searchValue={searchName}
/>

<div class="grow overflow-y-scroll">
  <div class="flex flex-col">
    {#each consumers.data as consumer (consumer.id)}
      <SidebarItem
        href={buildHref(`/consumers/${consumer.id}`)}
        only={[
          "consumer",
          "id",
          "events",
          "eventsMetrics",
          "eventsKpi",
          "subscriptionsCount",
        ]}
        isActive={selectedId === consumer.id}
        label={consumer.name}
        description={consumer.uid}
        data={{ filters: consumers.meta.filters }}
        preserveState={true}
        preserveScroll={true}
        prefetch={true}
      />
    {/each}
  </div>
</div>
