<script lang="ts">
  import type { Consumer, Event, Topic, Meta, GlobalFilters } from "$types";

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
  import { EventsTable } from "$containers";
  import {
    EllipsisIcon,
    ActivityIcon,
    CircleCheckIcon,
    TimerIcon,
    WebhookIcon,
    RotateCwIcon,
  } from "lucide-svelte";
  import ChartMetrics from "$containers/chart-metrics.svelte";
  import BadgeStatus from "$components/badge-status.svelte";
  import Section from "$components/section.svelte";
  import * as DropdownMenu from "$lib/components/ui/dropdown-menu";
  import CopyClipboard from "$components/copy-clipboard.svelte";
  import * as Dialog from "$lib/components/ui/dialog/index.js";
  import MetricsRangeSelect from "$containers/time-range-select.svelte";
  import { buildHref, getFilterValue } from "$utils";
  import { getSuccessRateLabel } from "$common";

  import { cn } from "$lib/utils";
  import { useDebounce } from "runed";
  import Skeleton from "$lib/components/ui/skeleton/skeleton.svelte";

  type Props = {
    consumers: { data: Consumer[]; meta: Meta };
    consumer?: Consumer;
    events?: { data: (Event & { topic: Topic })[]; meta: Meta };
    id?: string | null;
    globalFilters: GlobalFilters;
    organizationId: string;
    portalLink?: string;
    subscriptionsCount?: number;
    eventsKpi?: {
      totalAttempts: number;
      successRate: number;
      p95LatencyMs: number;
      successCount: number;
      failedCount: number;
    };
  };

  const {
    consumers,
    consumer,
    id,
    events,
    organizationId,
    portalLink,
    globalFilters,
    eventsKpi,
    subscriptionsCount,
  }: Props = $props();

  let searchName = $derived(
    getFilterValue(consumers.meta.filters, "name")[0]?.value,
  );

  let formIsOpen = $state(false);

  let showPortalLinkDialog = $state(false);

  const successRateLabel = $derived(
    eventsKpi && getSuccessRateLabel(eventsKpi.successRate),
  );

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

  const handleCreatePortalLink = () => {
    router.reload({
      only: ["portalLink"],
      onSuccess: () => {
        showPortalLinkDialog = true;
      },
    });
  };

  const handleRefresh = () => {
    router.reload({
      queryStringArrayFormat: "indices",
      except: ["consumers", "consumer"],
      showProgress: true,
    });
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
      {#each consumers.data as consumer (consumer.id)}
        <Link
          href={buildHref(`/consumers/${consumer.id}`)}
          only={[
            "consumer",
            "id",
            "events",
            "eventsMetrics",
            "eventsKpi",
            "subscriptionsCount",
          ]}
          class={cn(
            "flex items-center gap-1 px-6 py-4 border-b border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors text-left",
            id === consumer.id && "bg-gray-100",
          )}
          data={{ filters: consumers.meta.filters }}
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

<ContentWithSidebar {sidebar}>
  <div class="px-8 py-6 flex-1 flex flex-col gap-4 overflow-x-scroll">
    {#key id}
      {#if consumer}
        <header>
          <div class="flex items-center justify-between">
            <h1 class="text-xl font-semibold">{consumer.name}</h1>
            <DropdownMenu.Root>
              <DropdownMenu.Trigger>
                <Button variant="outline" size="icon">
                  <EllipsisIcon />
                </Button></DropdownMenu.Trigger
              >
              <DropdownMenu.Content align="end">
                <DropdownMenu.Group>
                  <DropdownMenu.Item onclick={handleCreatePortalLink}
                    >Portal link</DropdownMenu.Item
                  >
                  <DropdownMenu.Item>Edit</DropdownMenu.Item>
                  <DropdownMenu.Item>Disable</DropdownMenu.Item>
                </DropdownMenu.Group>
              </DropdownMenu.Content>
            </DropdownMenu.Root>
          </div>
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

        <div class="flex items-center justify-end gap-2">
          <div class="flex items-center gap-2">
            <span class="text-sm text-muted-foreground">Filters</span>
            <MetricsRangeSelect
              value={globalFilters.last}
              only={["globalFilters", "eventsKpi", "events", "eventsMetrics"]}
            />
          </div>
          <Button variant="outline" type="button" onclick={handleRefresh}>
            <RotateCwIcon />
          </Button>
        </div>

        <div class="flex flex-col gap-4">
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card.Root class="shadow-none py-4 gap-2">
              <Card.Header
                class="flex flex-row items-center justify-between pb-1 space-y-0"
              >
                <Card.Title
                  class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
                >
                  Total events
                </Card.Title>
                <div class="rounded-md bg-muted/60 p-1.5 text-muted-foreground">
                  <ActivityIcon class="size-4" />
                </div>
              </Card.Header>
              <Card.Content class="pt-0">
                <Deferred data="events">
                  {#snippet fallback()}
                    <div class="space-y-1.5">
                      <Skeleton class="h-8 w-24" />
                      <Skeleton class="h-3.5 w-32" />
                    </div>
                  {/snippet}
                  <div class="text-2xl lg:text-3xl font-bold tracking-tight">
                    {events?.meta?.totalCount != null
                      ? events.meta.totalCount.toLocaleString()
                      : "0"}
                  </div>
                  <p class="text-xs text-muted-foreground mt-1">
                    {eventsKpi?.totalAttempts != null
                      ? `${eventsKpi.totalAttempts.toLocaleString()} deliveries attempted`
                      : "Events received in period"}
                  </p>
                </Deferred>
              </Card.Content>
            </Card.Root>

            <Card.Root class="shadow-none py-4 gap-2">
              <Card.Header
                class="flex flex-row items-center justify-between pb-1 space-y-0"
              >
                <Card.Title
                  class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
                >
                  Success rate
                </Card.Title>
                <div class="rounded-md bg-muted/60 p-1.5 text-muted-foreground">
                  <CircleCheckIcon class="size-4" />
                </div>
              </Card.Header>
              <Card.Content class="pt-0">
                <Deferred data="eventsKpi">
                  {#snippet fallback()}
                    <div class="space-y-1.5">
                      <Skeleton class="h-8 w-24" />
                      <Skeleton class="h-3.5 w-28" />
                    </div>
                  {/snippet}
                  <div
                    class="text-2xl lg:text-3xl font-bold tracking-tight flex items-baseline gap-2"
                  >
                    <span
                      >{eventsKpi?.successRate != null
                        ? `${Math.round(eventsKpi.successRate)}%`
                        : "-"}</span
                    >
                    {#if eventsKpi?.successRate != null}
                      <BadgeStatus
                        label={successRateLabel.label}
                        variant={successRateLabel.variant}
                      />
                    {/if}
                  </div>
                  <p class="text-xs text-muted-foreground mt-1">
                    {#if eventsKpi && eventsKpi.failedCount > 0}
                      <span class="font-medium text-red-600 dark:text-red-400"
                        >{eventsKpi.failedCount.toLocaleString()}</span
                      > failed deliveries attempts
                    {:else}
                      <span
                        class="text-emerald-600 dark:text-emerald-400 font-medium"
                        >0 failed</span
                      > deliveries
                    {/if}
                  </p>
                </Deferred>
              </Card.Content>
            </Card.Root>

            <Card.Root class="shadow-none py-4 gap-2">
              <Card.Header
                class="flex flex-row items-center justify-between pb-1 space-y-0"
              >
                <Card.Title
                  class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
                >
                  P95 latency
                </Card.Title>
                <div class="rounded-md bg-muted/60 p-1.5 text-muted-foreground">
                  <TimerIcon class="size-4" />
                </div>
              </Card.Header>
              <Card.Content class="pt-0">
                <Deferred data="eventsKpi">
                  {#snippet fallback()}
                    <div class="space-y-1.5">
                      <Skeleton class="h-8 w-24" />
                      <Skeleton class="h-3.5 w-28" />
                    </div>
                  {/snippet}
                  <div class="text-2xl lg:text-3xl font-bold tracking-tight">
                    {eventsKpi?.p95LatencyMs != null
                      ? `${Math.round(eventsKpi.p95LatencyMs)} ms`
                      : "-"}
                  </div>
                  <p class="text-xs text-muted-foreground mt-1">
                    {eventsKpi?.p95LatencyMs != null
                      ? "95th percentile delivery time"
                      : "No delivery latency data"}
                  </p>
                </Deferred>
              </Card.Content>
            </Card.Root>

            <Card.Root class="shadow-none py-4 gap-2">
              <Card.Header
                class="flex flex-row items-center justify-between pb-1 space-y-0"
              >
                <Card.Title
                  class="text-xs font-medium text-muted-foreground uppercase tracking-wider"
                >
                  Subscriptions
                </Card.Title>
                <div class="rounded-md bg-muted/60 p-1.5 text-muted-foreground">
                  <WebhookIcon class="size-4" />
                </div>
              </Card.Header>
              <Card.Content class="pt-0">
                <Deferred data="subscriptionsCount">
                  {#snippet fallback()}
                    <div class="space-y-1.5">
                      <Skeleton class="h-8 w-24" />
                      <Skeleton class="h-3.5 w-28" />
                    </div>
                  {/snippet}
                  <div class="text-2xl lg:text-3xl font-bold tracking-tight">
                    {subscriptionsCount != null
                      ? subscriptionsCount.toLocaleString()
                      : "0"}
                  </div>
                  <p class="text-xs text-muted-foreground mt-1">
                    Active endpoint subscriptions
                  </p>
                </Deferred>
              </Card.Content>
            </Card.Root>
          </div>

          <div>
            <ChartMetrics propKey="eventsMetrics" />
          </div>
        </div>

        <Section title="Endpoints">
          <div>
            {#if consumer.endpoints}
              <EndpointsTable endpoints={consumer.endpoints} />
            {:else}
              <p>No endpoints found</p>
            {/if}
          </div>
        </Section>

        <EventsTable
          propsKey="events"
          columnVisibility={["insertedAt", "id", "topic", "status", "tags"]}
        />
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

<Dialog.Root bind:open={showPortalLinkDialog}>
  <Dialog.Content class="sm:max-w-4xl">
    <Dialog.Header>
      <Dialog.Title>Portal link</Dialog.Title>
      <Dialog.Description>
        <div class="flex items-center gap-2">
          <span class="font-mono text-sm">
            {portalLink}
          </span>
          <CopyClipboard value={portalLink} />
        </div>
      </Dialog.Description>
    </Dialog.Header>
  </Dialog.Content>
</Dialog.Root>
