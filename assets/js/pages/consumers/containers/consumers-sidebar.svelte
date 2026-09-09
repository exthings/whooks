<script lang="ts">
  import type { Consumer, Meta } from "$types";
  import SidebarHeader from "$components/sidebar-header.svelte";
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
                op: "like",
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
      <Link
        href={buildHref(`/consumers/${consumer.id}`)}
        only={[
          "consumer",
          "id",
          "events",
          "eventsMetrics",
          "eventsKpi",
          "subscriptionsCount",
        ]}
        class={cn(
          "flex items-center gap-1 px-6 py-4 border-b border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors text-left",
          selectedId === consumer.id && "bg-gray-100",
        )}
        data={{ filters: consumers.meta.filters }}
        preserveState={true}
        preserveScroll={true}
      >
        <div class="flex-1">
          <p
            class={cn(
              "text-sm",
              selectedId === consumer.id && "font-semibold text-primary",
            )}
          >
            {consumer.name}
          </p>
          <p class="text-[0.625rem] text-gray-500 font-mono">
            {consumer.uid}
          </p>
        </div>
      </Link>
    {/each}
  </div>
</div>
