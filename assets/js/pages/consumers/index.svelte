<script lang="ts">
  import type { Consumer, Event, Topic, Meta, GlobalFilters } from "$types";

  import { router } from "@inertiajs/svelte";
  import { Button } from "$lib/components/ui/button";
  import ContentWithSidebar from "$components/content-with-sidebar.svelte";
  import { EventsTable } from "$containers";
  import ChartMetrics from "$containers/chart-metrics.svelte";
  import MetricsRangeSelect from "$containers/time-range-select.svelte";
  import { RotateCwIcon } from "lucide-svelte";

  import {
    ConsumersSidebar,
    ConsumerHeader,
    ConsumerKpiCards,
    ConsumerEndpoints,
    ConsumerFormSheet,
    PortalLinkDialog,
  } from "./containers";

  type EventsKpi = {
    totalAttempts: number;
    successRate: number;
    p95LatencyMs: number;
    successCount: number;
    failedCount: number;
  };

  type Props = {
    consumers: { data: Consumer[]; meta: Meta };
    consumer?: Consumer;
    events?: { data: (Event & { topic: Topic })[]; meta: Meta };
    id?: string | null;
    globalFilters: GlobalFilters;
    organizationId: string;
    portalLink?: string;
    subscriptionsCount?: number;
    eventsKpi?: EventsKpi;
  };

  const {
    consumers,
    consumer,
    id,
    events,
    portalLink,
    globalFilters,
    eventsKpi,
    subscriptionsCount,
  }: Props = $props();

  let formIsOpen = $state(false);
  let showPortalLinkDialog = $state(false);

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
  <ConsumersSidebar
    {consumers}
    selectedId={id}
    onCreate={() => (formIsOpen = true)}
  />
{/snippet}

<ContentWithSidebar {sidebar}>
  <div class="px-8 py-6 flex-1 flex flex-col gap-4 overflow-x-scroll">
    {#key id}
      {#if consumer}
        <ConsumerHeader
          {consumer}
          onCreatePortalLink={handleCreatePortalLink}
        />

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

        <ConsumerKpiCards {events} {eventsKpi} {subscriptionsCount} />

        <ChartMetrics propKey="eventsMetrics" />

        <ConsumerEndpoints endpoints={consumer.endpoints} />

        <EventsTable
          propsKey="events"
          columnVisibility={["insertedAt", "id", "topic", "status", "tags"]}
        />
      {/if}
    {/key}
  </div>
</ContentWithSidebar>

<ConsumerFormSheet bind:open={formIsOpen} />

<PortalLinkDialog bind:open={showPortalLinkDialog} {portalLink} />
