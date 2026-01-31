<script lang="ts">
  import type { Snippet } from "svelte";

  import { Link } from "@inertiajs/svelte";

  import {
    Building2,
    SquareChartGantt,
    Box,
    Inbox,
    Settings2Icon,
  } from "lucide-svelte";

  import WhooksSymbol from "$components/whooks.svelte";

  import * as Sidebar from "$lib/components/ui/sidebar";
  import * as Collapsible from "$lib/components/ui/collapsible/index.js";

  type Props = {
    children: Snippet;
  };

  let { children }: Props = $props();

  const nav = [
    {
      title: "Organizations",
      url: "/ui/admin/organizations",
      icon: Building2,
    },
    {
      title: "Projects",
      url: "/ui/admin/projects",
      icon: Box,
      isActive: true,
      items: [
        {
          title: "Topics",
          url: "/ui/admin/topics",
          icon: Box,
        },
      ],
    },
    {
      title: "Consumers",
      url: "/ui/admin/consumers",
      icon: Inbox,
      isActive: true,
      items: [
        {
          title: "Endpoints",
          url: "/ui/admin/endpoints",
          icon: Box,
        },
      ],
    },
    {
      title: "Events",
      url: "/ui/admin/events",
      icon: SquareChartGantt,
      isActive: true,
      items: [
        {
          title: "Deliveries",
          url: "/ui/admin/deliveries",
          icon: Box,
        },
      ],
    },
    {
      title: "Settings",
      url: "/ui/admin/settings",
      icon: Settings2Icon,
    },
  ];
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
          {#each nav as mainItem (mainItem.title)}
            <Collapsible.Root open={mainItem.isActive}>
              {#snippet child({ props })}
                <Sidebar.MenuItem {...props}>
                  <Sidebar.MenuButton tooltipContent={mainItem.title}>
                    {#snippet child({ props })}
                      <a href={mainItem.url} {...props}>
                        <mainItem.icon />
                        <span>{mainItem.title}</span>
                      </a>
                    {/snippet}
                  </Sidebar.MenuButton>
                  {#if mainItem.items?.length}
                    <Collapsible.Trigger>
                      {#snippet child({ props })}
                        <Sidebar.MenuAction
                          {...props}
                          class="data-[state=open]:rotate-90"
                        >
                          <span class="sr-only">Toggle</span>
                        </Sidebar.MenuAction>
                      {/snippet}
                    </Collapsible.Trigger>
                    <Collapsible.Content>
                      <Sidebar.MenuSub>
                        {#each mainItem.items as subItem (subItem.title)}
                          <Sidebar.MenuSubItem>
                            <Sidebar.MenuSubButton href={subItem.url}>
                              <span>{subItem.title}</span>
                            </Sidebar.MenuSubButton>
                          </Sidebar.MenuSubItem>
                        {/each}
                      </Sidebar.MenuSub>
                    </Collapsible.Content>
                  {/if}
                </Sidebar.MenuItem>
              {/snippet}
            </Collapsible.Root>
          {/each}
        </Sidebar.Menu>
      </Sidebar.Group>
    </Sidebar.Content>
    <Sidebar.Footer></Sidebar.Footer>
  </Sidebar.Root>
  <Sidebar.Inset>
    <div class="overflow-hidden">
      {@render children()}
    </div>
  </Sidebar.Inset>
</Sidebar.Provider>
