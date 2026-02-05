<script lang="ts">
  import type { Analytics, Consumer, Event, Topic, Meta } from "$types";

  import { router, Link, Form, Deferred } from "@inertiajs/svelte";
  import * as Sheet from "$lib/components/ui/sheet";
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import { Button } from "$lib/components/ui/button";
  import * as Card from "$lib/components/ui/card";
  import ContentWithSidebar from "$components/content-with-sidebar.svelte";
  import SidebarHeader from "$components/sidebar-header.svelte";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import EndpointsTable from "./endpoints-table.svelte";
  import EventsTable from "./events-table.svelte";
  import { RotateCwIcon, PlusIcon } from "lucide-svelte";
  import ChartMetrics from "$containers/chart-metrics.svelte";
  import Section from "$components/section.svelte";

  import { getFilterValue } from "$utils";
  import { cn } from "$lib/utils";
  import { useDebounce } from "runed";

  type Props = {
    consumers: Consumer[];
    consumer?: Consumer;
    events?: { data: (Event & { topic: Topic })[]; meta: Meta };
    meta: Meta;
    id?: string | null;
    eventsAnalytics?: {
      data: Analytics[];
      interval: "minute" | "hour" | "day";
      last: "1h" | "12h" | "24h" | "48h" | "1w" | "1m";
    };
  };

  const { consumers, consumer, events, meta, id, eventsAnalytics }: Props =
    $props();

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

  const handleEndpointsRefresh = () => {
    router.get(
      "",
      {
        filters: meta.filters,
      },
      {
        queryStringArrayFormat: "indices",
        preserveState: true,
        only: ["endpoints"],
      },
    );
  };

  const handleEventsRefresh = () => {
    router.get(
      "",
      {
        filters: meta.filters,
      },
      {
        queryStringArrayFormat: "indices",
        preserveState: true,
        only: ["events"],
      },
    );
  };
</script>

<svelte:head>
  {#if consumer}
    <title>Consumers - {consumer.name}</title>
  {:else}
    <title>Consumers</title>
  {/if}
</svelte:head>

{#snippet sidebar()}
  <SidebarHeader
    title="Consumers"
    onCreate={() => (formIsOpen = true)}
    onSearch={handleSearch}
    searchValue={searchName}
  />

  <div class="grow overflow-y-scroll">
    <div class="flex flex-col">
      {#each consumers as consumer (consumer.id)}
        <Link
          href={`/ui/admin/consumers/${consumer.id}`}
          only={["consumer", "id", "events", "eventsAnalytics"]}
          class={cn(
            "flex items-center gap-1 px-6 py-4 border-b border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors text-left",
            id === consumer.id && "bg-gray-100",
          )}
          data={{ filters: meta.filters }}
          preserveState={true}
          preserveScroll={true}
        >
          <div class="flex-1">
            <p
              class={cn(
                "text-sm",
                id === consumer.id && "font-semibold text-primary",
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
{/snippet}

{#snippet endpointsActions()}
  <div>
    <Button
      size="sm"
      variant="outline"
      type="button"
      onclick={handleEndpointsRefresh}
    >
      <RotateCwIcon />
      Refresh
    </Button>
    <Button
      size="sm"
      variant="outline"
      type="button"
      onclick={handleEndpointsRefresh}
    >
      <PlusIcon />
      Add
    </Button>
  </div>
{/snippet}

{#snippet eventsActions()}
  <div>
    <Button
      size="sm"
      variant="outline"
      type="button"
      onclick={handleEventsRefresh}
    >
      <RotateCwIcon />
      Refresh
    </Button>
  </div>
{/snippet}

<ContentWithSidebar {sidebar}>
  <div class="px-8 py-6 flex-1 flex flex-col gap-6 overflow-x-scroll">
    {#key id}
      {#if consumer}
        <header>
          <h1 class="text-xl font-semibold">{consumer.name}</h1>
          <div class="w-full">
            <dl class="text-sm grid grid-cols-4 gap-4">
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">ID</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {consumer.id}
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">UID</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {consumer.uid}
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Inserted at</dt>
                <dd class="text-gray-700 sm:col-span-3">
                  <DateTimeDisplay
                    value={consumer.insertedAt}
                    size="sm"
                    options={{ fractionalSecondDigits: undefined }}
                  />
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Updated at</dt>
                <dd class="text-gray-700 sm:col-span-3">
                  <DateTimeDisplay
                    value={consumer.updatedAt}
                    size="sm"
                    options={{ fractionalSecondDigits: undefined }}
                  />
                </dd>
              </div>
            </dl>
          </div>
        </header>
        <div class="grid grid-cols-4 gap-4">
          <Card.Root class="shadow-none py-4 gap-1">
            <Card.Header>
              <Card.Title class="text-sm font-normal text-muted-foreground">
                Total endpoints
              </Card.Title>
            </Card.Header>
            <Card.Content>
              <p class="text-3xl">76</p>
            </Card.Content>
          </Card.Root>

          <Card.Root class="shadow-none py-4 gap-1">
            <Card.Header>
              <Card.Title class="text-sm font-normal text-muted-foreground">
                Success rate
              </Card.Title>
            </Card.Header>
            <Card.Content>
              <p class="text-3xl">76</p>
            </Card.Content>
          </Card.Root>

          <Card.Root class="shadow-none py-4 gap-1">
            <Card.Header>
              <Card.Title class="text-sm font-normal text-muted-foreground">
                Recent events
              </Card.Title>
            </Card.Header>
            <Card.Content>
              <p class="text-3xl">76</p>
            </Card.Content>
          </Card.Root>
        </div>

        <ChartMetrics propKey="eventsMetrics" />

        <Section title="Endpoints" actions={endpointsActions}>
          <div>
            {#if consumer.endpoints}
              <EndpointsTable endpoints={consumer.endpoints} />
            {:else}
              <p>No endpoints found</p>
            {/if}
          </div>
        </Section>

        <Section title="Events" actions={eventsActions}>
          <div>
            <Deferred data="events">
              {#snippet fallback()}
                <div>Loading...</div>
              {/snippet}
              {#if events}
                <EventsTable events={events.data} meta={events.meta} />
              {/if}
            </Deferred>
          </div>
        </Section>
      {/if}
    {/key}
  </div>
</ContentWithSidebar>

<Sheet.Root bind:open={formIsOpen}>
  <Sheet.Content side="right" class="">
    <Sheet.Header>
      <Sheet.Title>Create consumer</Sheet.Title>
    </Sheet.Header>
    <Form
      class="grid flex-1 auto-rows-min gap-6 px-4"
      method="post"
      action="/ui/admin/consumers"
      onSuccess={() => (formIsOpen = false)}
    >
      {#snippet children({ errors })}
        <div class="grid gap-2">
          <Label for="uid" class="text-end">Unique ID</Label>
          <Input id="uid" name="uid" />
          {#if errors["uid"]}
            <p class="text-red-500 text-sm">{errors["uid"]}</p>
          {/if}
        </div>
        <div class="grid gap-2">
          <Label for="name" class="text-end">Name</Label>
          <Input id="name" name="name" />
          {#if errors["name"]}
            <p class="text-red-500 text-sm">{errors["name"]}</p>
          {/if}
        </div>
        <Button type="submit">Create</Button>
      {/snippet}
    </Form>
  </Sheet.Content>
</Sheet.Root>
