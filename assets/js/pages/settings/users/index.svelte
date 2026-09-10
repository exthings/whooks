<script lang="ts">
  import type { User, Meta } from "$types";
  import { router } from "@inertiajs/svelte";
  import { Button } from "$lib/components/ui/button";
  import * as DropdownMenu from "$lib/components/ui/dropdown-menu";
  import * as Select from "$lib/components/ui/select";
  import { UserForm, UserUpdateForm } from "$containers";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import ContentWithSidebar from "$components/content-with-sidebar.svelte";
  import SidebarHeader from "$components/sidebar-header.svelte";
  import SidebarItem from "$components/sidebar-item.svelte";
  import { getFilterValue } from "$utils";
  import { useDebounce } from "runed";
  import {
    EllipsisVerticalIcon,
    Copy,
    Check,
    ShieldAlert,
  } from "lucide-svelte";
  import UserActivityFeed from "./components/user-activity-feed.svelte";

  type Props = {
    id: string | null;
    users: { data: User[]; meta: Meta };
    user?: User;
    currentUser?: User;
  };

  const { id, users, user, currentUser }: Props = $props();

  let searchName = $derived(
    getFilterValue(users.meta.filters, "name")[0]?.value,
  );

  let userFormOpen = $state(false);
  let userUpdateFormOpen = $state(false);

  const isSelfRootDemotion = $derived(
    currentUser?.id === user?.id && user?.role === "root",
  );

  const handleRoleChange = (newRole: string | undefined) => {
    if (!user?.id || !newRole || newRole === user.role) return;
    router.put(
      `/ui/admin/settings/users/${user.id}`,
      { role: newRole },
      {
        preserveState: true,
        preserveScroll: true,
      },
    );
  };

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
      {#each users.data as item (item.id)}
        <SidebarItem
          href={`/ui/admin/settings/users/${item.id}`}
          only={["id", "user"]}
          isActive={id === item.id}
          label={item.name}
          description={item.email}
          badge={item.role}
          data={{ filters: users.meta.filters }}
          preserveState={true}
          preserveScroll={true}
        />
      {/each}
    </div>
  </div>
{/snippet}

<ContentWithSidebar {sidebar}>
  <div class="px-8 py-6 flex-1 flex flex-col gap-6 overflow-y-auto">
    {#key id}
      {#if user}
        <header>
          <div class="flex justify-between pb-4">
            <div class="flex flex-col min-h-10">
              <h1 class="text-lg font-semibold">{user.name}</h1>
              <p class="text-xs text-muted-foreground font-mono">{user.id}</p>
            </div>
            <div class="flex items-center gap-2">
              <div class="flex flex-col items-end gap-1">
                <Select.Root
                  type="single"
                  disabled={isSelfRootDemotion}
                  value={user.role}
                  onValueChange={handleRoleChange}
                >
                  <Select.Trigger class="w-28 capitalize">
                    {user.role}
                  </Select.Trigger>
                  <Select.Content align="end">
                    <Select.Group>
                      <Select.Label>Role</Select.Label>
                      <Select.Item value="root" label="Root">Root</Select.Item>
                      <Select.Item value="admin" label="Admin"
                        >Admin</Select.Item
                      >
                      <Select.Item value="support" label="Support"
                        >Support</Select.Item
                      >
                    </Select.Group>
                  </Select.Content>
                </Select.Root>
              </div>

              <DropdownMenu.Root>
                <DropdownMenu.Trigger>
                  <Button variant="outline" size="icon">
                    <EllipsisVerticalIcon class="w-4 h-4" />
                  </Button>
                </DropdownMenu.Trigger>
                <DropdownMenu.Content align="end">
                  <DropdownMenu.Group>
                    <DropdownMenu.Item
                      onclick={() => (userUpdateFormOpen = true)}
                    >
                      Edit Details
                    </DropdownMenu.Item>
                  </DropdownMenu.Group>
                </DropdownMenu.Content>
              </DropdownMenu.Root>
            </div>
          </div>
          <div class="w-full">
            <dl class="text-sm grid grid-cols-5 gap-4">
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Email</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {user.email}
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Reference</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {user.externalId || "-"}
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
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Confirmed at</dt>
                <dd class="text-gray-700 sm:col-span-3">
                  <DateTimeDisplay
                    value={user.confirmedAt}
                    size="xs"
                    options={{ fractionalSecondDigits: undefined }}
                  />
                </dd>
              </div>
            </dl>
          </div>
        </header>

        <UserActivityFeed {user} />

        <UserUpdateForm data={user} bind:open={userUpdateFormOpen} />
      {/if}
      <UserForm bind:open={userFormOpen} />
    {/key}
  </div>
</ContentWithSidebar>
