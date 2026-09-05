<script lang="ts">
  import type { Scope } from "$types";
  import { type Snippet } from "svelte";
  import "@andypf/json-viewer";
  import { Link, page } from "@inertiajs/svelte";
  import {
    LayoutDashboardIcon,
    SquareChartGantt,
    CableIcon,
    Box,
    Inbox,
    UsersIcon,
    ChevronRightIcon,
  } from "lucide-svelte";

  import WhooksSymbol from "$components/whooks.svelte";
  import NavUser from "$components/nav-user.svelte";

  import * as Sidebar from "$lib/components/ui/sidebar";
  import * as Collapsible from "$lib/components/ui/collapsible/index.js";

  type Props = {
    children: Snippet;
    currentScope: Scope;
  };

  let { children, currentScope }: Props = $props();

  let nav = [
    {
      title: "Dashboard",
      url: `/ui/consumers/dashboard`,
      component: "consumers/portal/dashboard",
      icon: LayoutDashboardIcon,
    },
    {
      title: "Projects",
      url: `/ui/consumers/projects`,
      component: "consumers/portal/projects",
      icon: Box,
    },
    {
      title: "Endpoints",
      url: `/ui/consumers/endpoints`,
      component: "consumers/portal/endpoints",
      icon: CableIcon,
    },
    {
      title: "Events",
      url: `/ui/consumers/events`,
      component: "consumers/portal/events",
      icon: SquareChartGantt,
    },
  ];

  let settingsNav = [
    {
      title: "Users",
      url: `/ui/admin/settings/users`,
      component: "settings/users",
      icon: UsersIcon,
    },
  ];

  $inspect(currentScope);
</script>

<Sidebar.Provider>
  <!-- <AppSidebar /> -->
  <Sidebar.Root variant="inset">
    <Sidebar.Header>
      <Sidebar.Menu>
        <Sidebar.MenuItem>
          <Sidebar.MenuButton size="lg">
            {#snippet child({ props })}
              <Link href="/ui/admin/dashboard" {...props}>
                <div
                  class="bg-primary p-1 text-sidebar-primary-foreground flex aspect-square size-8 items-center justify-center rounded-lg"
                >
                  <WhooksSymbol class="fill-white" />
                </div>
                <div class="grid flex-1 text-left text-sm leading-tight">
                  <span class="truncate font-semibold">Whooks</span>
                </div>
              </Link>
            {/snippet}
          </Sidebar.MenuButton>
        </Sidebar.MenuItem>
      </Sidebar.Menu>
    </Sidebar.Header>
    <Sidebar.Content>
      <Sidebar.Group>
        <Sidebar.Menu>
          <Sidebar.MenuItem class="mb-2"></Sidebar.MenuItem>
          {#each nav as mainItem (mainItem.title)}
            <Collapsible.Root open={mainItem.isActive}>
              {#snippet child({ props })}
                <Sidebar.MenuItem {...props}>
                  <Sidebar.MenuButton
                    tooltipContent={mainItem.title}
                    isActive={$page.component.startsWith(mainItem.component)}
                  >
                    {#snippet child({ props })}
                      <Link href={mainItem.url} {...props}>
                        <mainItem.icon />
                        <span>{mainItem.title}</span>
                      </Link>
                    {/snippet}
                  </Sidebar.MenuButton>
                </Sidebar.MenuItem>
              {/snippet}
            </Collapsible.Root>
          {/each}
        </Sidebar.Menu>
      </Sidebar.Group>
    </Sidebar.Content>
    <Sidebar.Footer>
      {#if currentScope && currentScope.user}
        <NavUser name={currentScope.user.name} email={currentScope.user.email}
        ></NavUser>
      {/if}
    </Sidebar.Footer>
  </Sidebar.Root>
  <Sidebar.Inset>
    <div class="overflow-hidden">
      {@render children()}
    </div>
  </Sidebar.Inset>
</Sidebar.Provider>
