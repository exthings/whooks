<script lang="ts" module>
  export { default as layout } from "$layouts/portal.svelte";
</script>

<script lang="ts">
  import type { Endpoint, Meta, Subscription, Project, Topic } from "$types";

  import JsonViewer from "$components/json-viewer.svelte";

  import { Deferred, router } from "@inertiajs/svelte";
  import { Badge } from "$lib/components/ui/badge";
  import BadgeStatus from "$components/badge-status.svelte";
  import type { BadgeStatusVariant } from "$components/badge-status.svelte";
  import { Button } from "$lib/components/ui/button";
  import * as Tabs from "$lib/components/ui/tabs";
  import * as Card from "$lib/components/ui/card";

  import Section from "$components/section.svelte";
  import ContentWithSidebar from "$components/content-with-sidebar.svelte";
  import SidebarHeader from "$components/sidebar-header.svelte";
  import SidebarItem from "$components/sidebar-item.svelte";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import TopicDialog from "$components/topic-dialog.svelte";
  import { ScrollArea } from "$lib/components/ui/scroll-area/index.js";
  import { getFilterValue } from "$utils";
  import { useDebounce } from "runed";
  import { ChartMetrics, EventsTable } from "$containers";

  import Secret from "$components/secret.svelte";
  import {
    EllipsisVerticalIcon,
    BoxIcon,
    InboxIcon,
    PlusIcon,
    RotateCwIcon,
    XIcon,
  } from "lucide-svelte";

  type Props = {
    id: string;
    endpoints: { data: Endpoint[]; meta: Meta };
    endpoint?: Endpoint & {
      project: Project;
      subscriptions: (Subscription & { topic: Topic })[];
    };
  };

  const { id, endpoints, endpoint }: Props = $props();

  let searchName = $derived(
    getFilterValue(endpoints.meta.filters, "name")[0]?.value,
  );

  const handleEventsRefresh = () => {
    router.get(
      "",
      {},
      {
        queryStringArrayFormat: "indices",
        preserveState: true,
        only: ["events"],
      },
    );
  };
</script>

<svelte:head>
  <title>Whooks - Endpoints</title>
</svelte:head>

{#snippet sidebar()}
  <SidebarHeader title="Endpoints" searchValue={searchName} />

  <ScrollArea class="grow">
    <div class="flex flex-col">
      {#each endpoints.data as endpoint (endpoint.id)}
        <SidebarItem
          label={endpoint.url}
          description={endpoint.description}
          href={id ? `${endpoint.id}` : `endpoints/${endpoint.id}`}
          only={["id", "endpoint"]}
          isActive={id === endpoint.id}
          data={{ filters: endpoints.meta.filters }}
          preserveState={true}
          preserveScroll={true}
        />
      {/each}
    </div>
  </ScrollArea>
{/snippet}

{#snippet subscriptionsActions()}
  <div>
    <Button
      size="icon"
      variant="outline"
      type="button"
      onclick={handleEventsRefresh}
    >
      <PlusIcon />
    </Button>
  </div>
{/snippet}

<ContentWithSidebar {sidebar}>
  {#if endpoint}
    <ScrollArea class="px-8 py-6 w-full">
      <div class="flex flex-col gap-4">
        <header class="flex flex-col gap-4">
          <div class="flex items-start justify-between">
            <div class="flex items-start gap-4">
              <div>
                <h1 class="text-lg font-semibold font-mono">{endpoint.url}</h1>
                <p class="text-xs text-gray-500">{endpoint.description}</p>
              </div>
              <BadgeStatus
                variant={endpoint.status === "enabled"
                  ? "success"
                  : "destructive"}
                label={endpoint.status}
              />
            </div>
            <div>
              <Button variant="outline" size="sm">
                <EllipsisVerticalIcon />
              </Button>
            </div>
          </div>
          <div class="w-full">
            <dl class="text-sm grid grid-cols-4 gap-4">
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">ID</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {endpoint.id}
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">UID</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {endpoint.uid || "-"}
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Inserted at</dt>
                <dd class="text-gray-700 sm:col-span-3">
                  <DateTimeDisplay
                    value={endpoint.insertedAt}
                    size="xs"
                    options={{ fractionalSecondDigits: undefined }}
                  />
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Updated at</dt>
                <dd class="text-gray-700 sm:col-span-3">
                  <DateTimeDisplay
                    value={endpoint.updatedAt}
                    size="xs"
                    options={{ fractionalSecondDigits: undefined }}
                  />
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Project</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  <Badge variant="outline"
                    ><BoxIcon />{endpoint.project.name}</Badge
                  >
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Secret</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  <Secret value={endpoint.secret} />
                </dd>
              </div>
            </dl>
          </div>
        </header>

        <div class="grid grid-cols-3 gap-6">
          <div class="col-span-2">
            <ChartMetrics propKey="eventsMetrics" />
          </div>

          <Section title="Subscriptions" actions={subscriptionsActions}>
            <Card.Root class="shadow-none py-0 px-0 p-0 gap-1 h-72">
              <Card.Content class="p-0">
                <ul class="flex flex-col divide-y divide-gray-200">
                  {#each endpoint.subscriptions as subscription (subscription.id)}
                    <li class="flex items-center justify-between py-2 px-4">
                      <div>
                        <p class="font-mono text-sm">
                          {subscription.topic.name}
                        </p>
                        <p class="text-muted-foreground text-xs">
                          {subscription.topic.description}
                        </p>
                      </div>
                      <div>
                        <Button
                          variant="ghost"
                          size="icon"
                          class="rounded-full"
                          onclick={() => {
                            removeSubscriptionDialog = true;
                          }}
                        >
                          <XIcon />
                        </Button>
                      </div>
                    </li>
                  {/each}
                </ul>
              </Card.Content>
            </Card.Root>
          </Section>
        </div>

        <EventsTable
          propsKey="events"
          columnVisibility={["insertedAt", "id", "topic", "status", "tags"]}
          hrefBuilder={(id) => `/ui/consumers/events/${id}`}
        />

        <div class="col-span-2 flex flex-col gap-2">
          <h2 class="font-semibold">Headers</h2>
          <Card.Root class="shadow-none py-4 gap-1">
            <Card.Content>
              <div>
                <andypf-json-viewer data={endpoint.headers}
                ></andypf-json-viewer>
              </div>
            </Card.Content>
          </Card.Root>
        </div>
      </div>
    </ScrollArea>
  {:else}
    <h1>Endpoints consumers</h1>
  {/if}
</ContentWithSidebar>
