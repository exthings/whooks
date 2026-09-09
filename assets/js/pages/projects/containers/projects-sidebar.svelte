<script lang="ts">
  import type { Project, Meta } from "$types";
  import SidebarHeader from "$components/sidebar-header.svelte";
  import SidebarItem from "$components/sidebar-item.svelte";
  import { buildHref, getFilterValue } from "$utils";
  import { useDebounce } from "runed";
  import { router } from "@inertiajs/svelte";

  type Props = {
    projects: { data: Project[]; meta: Meta };
    selectedId: string | null;
    onCreate: () => void;
  };

  const { projects, selectedId, onCreate }: Props = $props();

  const searchName = $derived(
    getFilterValue(projects.meta.filters, "name")[0]?.value,
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
  title="Projects"
  {onCreate}
  onSearch={handleSearch}
  searchValue={searchName}
/>

<div class="grow overflow-y-scroll">
  <div class="flex flex-col">
    {#each projects.data as project (project.id)}
      <SidebarItem
        href={buildHref(`/projects/${project.id}`)}
        only={[
          "id",
          "project",
          "events",
          "subscriptions",
          "eventsKpi",
          "eventsMetrics",
        ]}
        isActive={selectedId === project.id}
        label={project.name}
        description={project.uid}
        data={{ filters: projects.meta.filters }}
        preserveState={true}
        preserveScroll={true}
      />
    {/each}
  </div>
</div>
