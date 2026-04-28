<script lang="ts">
  import type { Scope } from "$types";
  import { onMount, type Snippet } from "svelte";
  import "@andypf/json-viewer";
  import { Link, page, router } from "@inertiajs/svelte";
  import OrganizationsCombobox from "$containers/organizations-combobox.svelte";
  import { SquareChartGantt, Box, Inbox, Settings2Icon } from "lucide-svelte";

  import WhooksSymbol from "$components/whooks.svelte";
  import NavUser from "$components/nav-user.svelte";

  import * as Sidebar from "$lib/components/ui/sidebar";
  import * as Collapsible from "$lib/components/ui/collapsible/index.js";
  import { PersistedState } from "runed";

  type Props = {
    children: Snippet;
    currentScope: Scope;
    organizationId: string;
  };

  let { children, currentScope, organizationId }: Props = $props();

  let organization = new PersistedState<string | null>(
    "organization",
    organizationId,
  );

  let nav = $derived(
    organization.current
      ? [
          {
            title: "Projects",
            url: `/ui/admin/${organization.current}/projects`,
            component: "projects",
            icon: Box,
            isActive: true,
          },
          {
            title: "Consumers",
            url: `/ui/admin/${organization.current}/consumers`,
            component: "consumers",
            icon: Inbox,
            isActive: true,
          },
          {
            title: "Events",
            url: `/ui/admin/${organization.current}/events`,
            component: "events",
            icon: SquareChartGantt,
            isActive: true,
          },
          {
            title: "Settings",
            url: `/ui/admin/${organization.current}/settings`,
            component: "settings",
            icon: Settings2Icon,
          },
        ]
      : [],
  );

  const setOrganization = (org: string) => {
    console.log("crt org", organization.current);
    console.log("new org", org);
    console.log($page.url);
    const newUrl = $page.url.replace(organization.current, org);
    organization.current = org;
    router.get(newUrl, {}, { preserveState: true });
  };

  onMount(() => {
    if (organization.current === null && $page.props.organizationId) {
      organization.current = $page.props.organizationId;
    }
  });

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
          <Sidebar.MenuItem class="mb-2">
            <OrganizationsCombobox {organization} {setOrganization} />
          </Sidebar.MenuItem>
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
