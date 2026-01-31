<script lang="ts">
  import type { Organization } from "$types/organization";
  import type { Meta } from "$types/meta";

  import { router, Link } from "@inertiajs/svelte";
  import * as Sheet from "$lib/components/ui/sheet";
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import { Button } from "$lib/components/ui/button";
  import ContentWithSidebar from "$components/content-with-sidebar.svelte";
  import SidebarHeader from "$components/sidebar-header.svelte";
  import { getFilterValue } from "$utils";
  import { cn } from "$lib/utils";
  import { useDebounce } from "runed";

  type Props = {
    organizations: Organization[];
    meta: Meta;
    id: string | null;
  };

  const { organizations, meta, id }: Props = $props();

  let searchName = $derived(getFilterValue(meta.filters, "name")[0]?.value);

  let formIsOpen = $state(false);

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

{#snippet sidebar()}
  <SidebarHeader
    title="Organizations"
    onCreate={() => (formIsOpen = true)}
    onSearch={handleSearch}
    searchValue={searchName}
  />

  <div class="grow overflow-y-scroll">
    <div class="flex flex-col">
      {#each organizations as org (org.id)}
        <Link
          href={`/ui/admin/organizations/${org.id}`}
          only={["organization", "id"]}
          class={cn(
            "flex items-center gap-2 px-6 py-4 border-b border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors text-left",
            id === org.id && "bg-gray-100",
          )}
          data={{ filters: meta.filters }}
          preserveState={true}
          preserveScroll={true}
        >
          {#if id === org.id}
            <div class="w-1 h-8 rounded-full bg-primary"></div>
          {/if}
          <div class="flex-1">
            <p class={cn("text-sm", id === org.id && "font-semibold")}>
              {org.name}
            </p>
          </div>
        </Link>
      {/each}
    </div>
  </div>
{/snippet}

<ContentWithSidebar {sidebar}>
  <div></div>
</ContentWithSidebar>

<Sheet.Root bind:open={formIsOpen}>
  <Sheet.Content side="right" class="">
    <Sheet.Header>
      <Sheet.Title>Create organization</Sheet.Title>
    </Sheet.Header>
    <div class="grid flex-1 auto-rows-min gap-6 px-4">
      <div class="grid gap-3">
        <Label for="name" class="text-end">Name</Label>
        <Input id="name" />
      </div>
    </div>
    <Sheet.Footer>
      <Button type="submit">Create</Button>
    </Sheet.Footer>
  </Sheet.Content>
</Sheet.Root>
