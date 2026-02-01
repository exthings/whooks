<script lang="ts">
  import type {
    Endpoint,
    Consumer,
    Project,
    Subscription,
    Topic,
    Event,
    Meta,
  } from "$types";
  import * as Select from "$lib/components/ui/select";
  import { Button } from "$lib/components/ui/button";
  import ContentWithSidebar from "$components/content-with-sidebar.svelte";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import BadgeStatus from "$components/badge-status.svelte";
  import * as Card from "$lib/components/ui/card";
  import { BarChartEvents } from "$components/charts";
  import { router, Deferred } from "@inertiajs/svelte";
  import * as AlertDialog from "$lib/components/ui/alert-dialog/index.js";
  import { buttonVariants } from "$lib/components/ui/button/index.js";

  import EventsTable from "$components/events-table.svelte";

  import {
    EllipsisVerticalIcon,
    BoxIcon,
    InboxIcon,
    PlusIcon,
    RotateCwIcon,
    XIcon,
  } from "lucide-svelte";
  import { Badge } from "$lib/components/ui/badge";

  type Props = {
    endpoint: Endpoint & {
      consumer: Consumer;
      project: Project;
      subscriptions: (Subscription & { topic: Topic })[];
    };
    events: { data: (Event & { topic: Topic })[]; meta: Meta };
  };

  const { endpoint, events }: Props = $props();

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

  const metricsRange = [
    { value: "12h", label: "12h" },
    { value: "24h", label: "24h" },
    { value: "48h", label: "48h" },
    { value: "1w", label: "1w" },
    { value: "1m", label: "1m" },
  ];

  let metricsRangeValue = $state("12h");

  const metricsRangeContent = $derived(
    metricsRange.find((f) => f.value === metricsRangeValue)?.label ??
      "Select a fruit",
  );

  let removeSubscriptionDialog = $state(false);
</script>

<svelte:head>
  <title>Endpoint - {endpoint.id.slice(endpoint.id.length - 6)}</title>
</svelte:head>

<ContentWithSidebar>
  <div class="p-6 flex flex-col gap-8 flex-1 overflow-x-scroll">
    <header class="flex flex-col gap-4">
      <div class="flex items-start justify-between">
        <div class="flex items-start gap-4">
          <div>
            <h1 class="text-lg font-semibold font-mono">{endpoint.url}</h1>
            <p class="text-xs text-gray-500">{endpoint.description}</p>
          </div>
          <BadgeStatus
            variant={endpoint.status === "enabled" ? "success" : "destructive"}
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
                size="sm"
                options={{ fractionalSecondDigits: undefined }}
              />
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Updated at</dt>
            <dd class="text-gray-700 sm:col-span-3">
              <DateTimeDisplay
                value={endpoint.updatedAt}
                size="sm"
                options={{ fractionalSecondDigits: undefined }}
              />
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Consumer</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              <Badge variant="outline">
                <InboxIcon />
                {endpoint.consumer.name}</Badge
              >
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Project</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              <Badge variant="outline"><BoxIcon />{endpoint.project.name}</Badge
              >
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Secret</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              {endpoint.secret || "-"}
            </dd>
          </div>
        </dl>
      </div>
    </header>

    <div class="grid grid-cols-3 gap-6">
      <div class="col-span-2 flex flex-col gap-2">
        <div class="flex items-center justify-between pb-2">
          <h2 class="font-semibold">Metrics</h2>
          <Select.Root
            type="single"
            name="metricsRange"
            bind:value={metricsRangeValue}
          >
            <Select.Trigger class="w-24">
              {metricsRangeContent}
            </Select.Trigger>
            <Select.Content>
              <Select.Group>
                {#each metricsRange as range (range.value)}
                  <Select.Item
                    value={range.value}
                    label={range.label}
                    disabled={range.value === "grapes"}
                  >
                    {range.label}
                  </Select.Item>
                {/each}
              </Select.Group>
            </Select.Content>
          </Select.Root>
        </div>
        <Card.Root class="shadow-none py-4 gap-1 h-72">
          <Card.Content class="h-full">
            <BarChartEvents />
          </Card.Content>
        </Card.Root>
      </div>

      <div class="flex flex-col gap-2">
        <div class="flex items-center justify-between pb-2">
          <h2 class="font-semibold">Subscriptions</h2>
          <Button
            size="icon"
            variant="outline"
            type="button"
            onclick={handleEventsRefresh}
          >
            <PlusIcon />
          </Button>
        </div>
        <Card.Root
          class="shadow-none py-0 px-0 p-0 gap-1 h-72 overflow-x-scroll"
        >
          <Card.Content class="p-0">
            <ul class="flex flex-col divide-y divide-gray-200">
              {#each endpoint.subscriptions as subscription (subscription.id)}
                <li class="flex items-center justify-between py-2 px-4">
                  <div>
                    <p class="font-mono text-sm">{subscription.topic.name}</p>
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
      </div>
    </div>

    <div class="flex flex-col gap-2">
      <div class="flex items-center justify-between pb-2">
        <h2 class="font-semibold">Latest delivery attempts</h2>
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
      <Deferred data="events">
        {#snippet fallback()}
          <div>Loading...</div>
        {/snippet}
        {#if events}
          <EventsTable events={events.data} meta={events.meta} />
        {/if}
      </Deferred>
    </div>

    <div class="col-span-2 flex flex-col gap-2">
      <h2 class="font-semibold">Headers</h2>
      <Card.Root class="shadow-none py-4 gap-1">
        <Card.Content>
          <div>
            <andypf-json-viewer data={endpoint.headers}></andypf-json-viewer>
          </div>
        </Card.Content>
      </Card.Root>
    </div>
  </div>
</ContentWithSidebar>

<AlertDialog.Root bind:open={removeSubscriptionDialog}>
  <AlertDialog.Content>
    <AlertDialog.Header>
      <AlertDialog.Title>Are you sure?</AlertDialog.Title>
      <AlertDialog.Description>
        This action cannot be undone. This will disable subscriptions for this
        endpoint.
      </AlertDialog.Description>
    </AlertDialog.Header>
    <AlertDialog.Footer>
      <AlertDialog.Cancel>Cancel</AlertDialog.Cancel>
      <AlertDialog.Action>Confirm</AlertDialog.Action>
    </AlertDialog.Footer>
  </AlertDialog.Content>
</AlertDialog.Root>
