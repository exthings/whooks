<script lang="ts">
  import type { User, Meta } from "$types";

  import { Deferred, router } from "@inertiajs/svelte";
  import BadgeStatus from "$components/badge-status.svelte";
  import type { BadgeStatusVariant } from "$components/badge-status.svelte";
  import { Button } from "$lib/components/ui/button";
  import * as DropdownMenu from "$lib/components/ui/dropdown-menu";
  import * as Tabs from "$lib/components/ui/tabs";
  import * as Card from "$lib/components/ui/card";

  import Section from "$components/section.svelte";
  import { UserForm, UserUpdateForm } from "$containers";
  import ContentWithSidebar from "$components/content-with-sidebar.svelte";
  import SidebarHeader from "$components/sidebar-header.svelte";
  import SidebarItem from "$components/sidebar-item.svelte";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import { getFilterValue } from "$utils";
  import { useDebounce } from "runed";
  import { EllipsisVerticalIcon } from "lucide-svelte";

  type Props = {
    id: string | null;
    users: { data: User[]; meta: Meta };
    user?: User;
  };

  const { id, users, user }: Props = $props();

  let searchName = $derived(
    getFilterValue(users.meta.filters, "name")[0]?.value,
  );

  let userFormOpen = $state(false);
  let userUpdateFormOpen = $state(false);

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

<svelte:head>
  {#if user}
    <title>User - {user.name}</title>
  {:else}
    <title>Users</title>
  {/if}
</svelte:head>

{#snippet sidebar()}
  <SidebarHeader
    title="Users"
    onCreate={() => (userFormOpen = true)}
    onSearch={handleSearch}
    searchValue={searchName}
  />

  <div class="grow overflow-y-scroll">
    <div class="flex flex-col">
      {#each users.data as user (user.id)}
        <SidebarItem
          href={`/ui/admin/settings/users/${user.id}`}
          only={["id", "user"]}
          isActive={id === user.id}
          label={user.name}
          description={user.email}
          data={{ filters: users.meta.filters }}
          preserveState={true}
          preserveScroll={true}
        />
      {/each}
    </div>
  </div>
{/snippet}

<ContentWithSidebar {sidebar}>
  <div class="px-8 py-6 flex-1 flex flex-col gap-6 overflow-x-scroll">
    {#key id}
      {#if user}
        <header>
          <div class="flex justify-between pb-4">
            <div class="flex flex-col min-h-10">
              <h1 class="text-xl font-semibold">{user.name}</h1>
              <p class="text-xs">{user.id}</p>
            </div>
            <DropdownMenu.Root>
              <DropdownMenu.Trigger>
                <Button variant="outline" size="icon">
                  <EllipsisVerticalIcon />
                </Button>
              </DropdownMenu.Trigger>
              <DropdownMenu.Content align="end">
                <DropdownMenu.Group>
                  <DropdownMenu.Item onclick={() => (userUpdateFormOpen = true)}
                    >Edit</DropdownMenu.Item
                  >
                </DropdownMenu.Group>
              </DropdownMenu.Content>
            </DropdownMenu.Root>
          </div>
          <div class="w-full">
            <dl class="text-sm grid grid-cols-4 gap-4">
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Role</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {user.role}
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Email</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {user.email}
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Inserted at</dt>
                <dd class="text-gray-700 sm:col-span-3">
                  <DateTimeDisplay
                    value={user.insertedAt}
                    size="xs"
                    options={{ fractionalSecondDigits: undefined }}
                  />
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Updated at</dt>
                <dd class="text-gray-700 sm:col-span-3">
                  <DateTimeDisplay
                    value={user.updatedAt}
                    size="xs"
                    options={{ fractionalSecondDigits: undefined }}
                  />
                </dd>
              </div>
            </dl>
          </div>
        </header>
        <UserUpdateForm data={user} bind:open={userUpdateFormOpen} />
      {/if}
      <UserForm bind:open={userFormOpen} />
    {/key}
  </div></ContentWithSidebar
>
