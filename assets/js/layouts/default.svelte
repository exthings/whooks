<script lang="ts">
  import type { Snippet } from "svelte";

  import { Link } from "@inertiajs/svelte";

  import {
    FishingHook,
    Building2,
    SquareChartGantt,
    Box,
    Inbox,
    ClipboardList,
    List,
    Settings2Icon,
    ChevronRightIcon,
  } from "lucide-svelte";

  import * as Sidebar from "$lib/components/ui/sidebar";
  import * as Collapsible from "$lib/components/ui/collapsible/index.js";

  type Props = {
    children: Snippet;
  };

  let { children }: Props = $props();

  const nav = [
    {
      title: "Organizations",
      url: "#",
      icon: Building2,
    },
    {
      title: "Projects",
      url: "#",
      icon: Box,
      isActive: true,
      items: [
        {
          title: "Topics",
          url: "#",
          icon: Box,
        },
      ],
    },
    {
      title: "Consumers",
      url: "#",
      icon: Inbox,
      isActive: true,
      items: [
        {
          title: "Endpoints",
          url: "#",
          icon: Box,
        },
      ],
    },
    {
      title: "Events",
      url: "#",
      icon: SquareChartGantt,
      isActive: true,
      items: [
        {
          title: "Deliveries",
          url: "#",
          icon: Box,
        },
      ],
    },
    {
      title: "Settings",
      url: "#",
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
                  class="bg-sidebar-primary text-sidebar-primary-foreground flex aspect-square size-8 items-center justify-center rounded-lg"
                >
                  <FishingHook size={20} />
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
    <div class="px-6 py-4 h-full flex flex-col">
      {@render children()}
    </div>
  </Sidebar.Inset>
</Sidebar.Provider>
