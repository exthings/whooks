<script lang="ts">
  import type { Project, Topic, Meta, GlobalFilters } from "$types";

  import ContentWithSidebar from "$components/content-with-sidebar.svelte";
  import EventsTable from "$containers/events-table.svelte";
  import ChartMetrics from "$containers/chart-metrics.svelte";
  import MetricsRangeSelect from "$containers/time-range-select.svelte";
  import RefreshButton from "$containers/refresh-button.svelte";

  import {
    ProjectsSidebar,
    ProjectHeader,
    ProjectKpiCards,
    ProjectTopics,
    ProjectFormDialog,
    TopicDialog,
    TopicFormDialog,
  } from "./containers";

  type Subscriptions = {
    topicId: string;
    count: number;
  };

  type EventsKpi = {
    totalAttempts: number;
    successRate: number;
    p95LatencyMs: number;
    successCount: number;
    failedCount: number;
  };

  type Props = {
    id: string | null;
    projects: { data: Project[]; meta: Meta };
    project?: Project & { topics: Topic[] };
    events?: { meta: Meta };
    subscriptions?: Subscriptions[];
    globalFilters: GlobalFilters;
    eventsKpi?: EventsKpi;
  };

  const {
    id,
    projects,
    project,
    events,
    subscriptions,
    globalFilters,
    eventsKpi,
  }: Props = $props();

  let projectFormOpen = $state(false);
  let selectedTopic = $state<Topic | null>(null);
  let topicFormOpen = $state(false);
</script>

<svelte:head>
  {#if project}
    <title>Project - {project.name}</title>
  {:else}
    <title>Projects</title>
  {/if}
</svelte:head>

{#snippet sidebar()}
  <ProjectsSidebar
    {projects}
    selectedId={id}
    onCreate={() => (projectFormOpen = true)}
  />
{/snippet}

<ContentWithSidebar {sidebar}>
  <div class="px-8 py-6 flex-1 flex flex-col gap-4 overflow-x-scroll">
    {#key id}
      {#if project}
        <ProjectHeader {project} />

        <div class="flex items-center justify-end gap-2">
          <div class="flex items-center gap-2">
            <span class="text-sm text-muted-foreground">Filters</span>
            <MetricsRangeSelect
              value={globalFilters.last}
              only={["globalFilters", "eventsKpi", "events", "eventsMetrics"]}
            />
          </div>
          <RefreshButton except={["consumers", "consumer"]} />
        </div>

        <ProjectKpiCards {events} {eventsKpi} {subscriptions} />

        <ChartMetrics propKey="eventsMetrics" />

        <ProjectTopics
          topics={project.topics}
          {subscriptions}
          onAddTopic={() => (topicFormOpen = true)}
          onViewTopic={(topic) => (selectedTopic = topic)}
        />

        <EventsTable
          propsKey="events"
          columnVisibility={[
            "insertedAt",
            "id",
            "consumer",
            "topic",
            "status",
            "tags",
          ]}
        />
      {/if}
    {/key}
  </div>
</ContentWithSidebar>

<ProjectFormDialog bind:open={projectFormOpen} />

<TopicDialog topic={selectedTopic} />

<TopicFormDialog bind:open={topicFormOpen} projectId={id} />
