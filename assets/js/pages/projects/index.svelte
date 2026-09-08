<script lang="ts">
  import type { Project, Topic, Meta, GlobalFilters } from "$types";

  import { Deferred, router } from "@inertiajs/svelte";
  import BadgeStatus from "$components/badge-status.svelte";
  import type { BadgeStatusVariant } from "$components/badge-status.svelte";
  import { Button } from "$lib/components/ui/button";
  import * as Card from "$lib/components/ui/card";

  import Section from "$components/section.svelte";
  import ContentWithSidebar from "$components/content-with-sidebar.svelte";
  import SidebarHeader from "$components/sidebar-header.svelte";
  import SidebarItem from "$components/sidebar-item.svelte";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import EventsTable from "$containers/events-table.svelte";
  import { getFilterValue, buildHref } from "$utils";
  import ChartMetrics from "$containers/chart-metrics.svelte";
  import { useDebounce } from "runed";
  import {
    EllipsisIcon,
    EyeIcon,
    PlusIcon,
    ActivityIcon,
    CircleCheckIcon,
    TimerIcon,
    WebhookIcon,
  } from "lucide-svelte";
  import MetricsRangeSelect from "$containers/time-range-select.svelte";
  import RefreshButton from "$containers/refresh-button.svelte";
  import Skeleton from "$lib/components/ui/skeleton/skeleton.svelte";
  import { getSuccessRateLabel } from "$common";

  import ProjectFormDialog from "./containers/project-form-dialog.svelte";
  import TopicDialog from "./containers/topic-dialog.svelte";
  import TopicFormDialog from "./containers/topic-form-dialog.svelte";

  type Subscriptions = {
    topicId: string;
    count: number;
  };

  type Props = {
    id: string | null;
    projects: { data: Project[]; meta: Meta };
    project?: Project & { topics: Topic[] };
    events?: { meta: Meta };
    subscriptions?: Subscriptions[];
    globalFilters: GlobalFilters;
    eventsKpi?: {
      totalAttempts: number;
      successRate: number;
      p95LatencyMs: number;
      successCount: number;
      failedCount: number;
    };
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

  const STATUS_MAP: Record<Project["status"], BadgeStatusVariant> = {
    enabled: "success",
    disabled: "destructive",
  };

  let searchName = $derived(
    getFilterValue(projects.meta.filters, "name")[0]?.value,
  );

  let projectFormOpen = $state(false);
  let selectedTopic = $state<Topic | null>(null);
  let topicFormOpen = $state(false);

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
</script>

<svelte:head>
  {#if project}
    <title>Project - {project.name}</title>
  {:else}
    <title>Projects</title>
  {/if}
</svelte:head>

{#snippet sidebar()}
  <SidebarHeader
    title="Projects"
    onCreate={() => (projectFormOpen = true)}
    onSearch={handleSearch}
    searchValue={searchName}
  />

  <div class="grow overflow-y-scroll">
    <div class="flex flex-col">
      {#each projects.data as project (project.id)}
        <SidebarItem
          href={buildHref(`/projects/${project.id}`)}
          only={[
            "id",
            "project",
            "events",
            "subscriptions",
            "eventsKpi",
            "eventsMetrics",
          ]}
          isActive={id === project.id}
          label={project.name}
          description={project.uid}
          data={{ filters: projects.meta.filters }}
          preserveState={true}
          preserveScroll={true}
        />
      {/each}
    </div>
  </div>
{/snippet}

{#snippet topicsActions()}
  <Button variant="outline" size="icon" onclick={() => (topicFormOpen = true)}
    ><PlusIcon /></Button
  >
{/snippet}

<ContentWithSidebar {sidebar}>
  <div class="px-8 py-6 flex-1 flex flex-col gap-4 overflow-x-scroll">
    {#key id}
      {#if project}
        <header>
          <div class="flex justify-between">
            <div class="flex items-center gap-2 min-h-10">
              <h1 class="text-xl font-semibold">{project.name}</h1>
              <BadgeStatus
                variant={STATUS_MAP[project.status]}
                label={project.status}
              />
            </div>
            <Button variant="outline" size="icon">
              <EllipsisIcon />
            </Button>
          </div>
          <div class="w-full">
            <dl class="text-sm grid grid-cols-4 gap-4">
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">ID</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {project.id}
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">UID</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {project.uid}
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Inserted at</dt>
                <dd class="text-gray-700 sm:col-span-3">
                  <DateTimeDisplay
                    value={project.insertedAt}
                    size="xs"
                    options={{ fractionalSecondDigits: undefined }}
                  />
                </dd>
              </div>
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Updated at</dt>
                <dd class="text-gray-700 sm:col-span-3">
                  <DateTimeDisplay
                    value={project.updatedAt}
                    size="xs"
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
          <RefreshButton except={["consumers", "consumer"]} />
        </div>

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
                      ? `${eventsKpi.successRate}%`
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
              <Deferred data="subscriptions">
                {#snippet fallback()}
                  <div class="space-y-1.5">
                    <Skeleton class="h-8 w-24" />
                    <Skeleton class="h-3.5 w-28" />
                  </div>
                {/snippet}
                <div class="text-2xl lg:text-3xl font-bold tracking-tight">
                  {subscriptions
                    ? subscriptions.reduce((acc, s) => acc + s.count, 0)
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

        <Section title="Topics" actions={topicsActions}>
          <Card.Root class="shadow-none py-0 px-0 p-0 gap-1 overflow-x-scroll">
            <Card.Content class="p-0">
              <ul class="flex flex-col divide-y divide-gray-200">
                {#each project.topics as topic (topic.id)}
                  <li class="flex items-center justify-between py-2 px-4">
                    <div>
                      <div class="flex items-center gap-2">
                        <p class="font-mono text-sm">{topic.name}</p>
                        <span class="text-xs bg-gray-200 rounded px-1.5 py-0.5">
                          {subscriptions?.find(
                            (sub) => sub.topicId === topic.id,
                          )?.count ?? "-"}
                        </span>
                      </div>
                      <p class="text-muted-foreground text-xs">
                        {topic.description}
                      </p>
                    </div>
                    <div>
                      <Button
                        variant="outline"
                        size="sm"
                        onclick={() => (selectedTopic = topic)}
                      >
                        <EyeIcon />
                      </Button>
                    </div>
                  </li>
                {/each}
              </ul>
            </Card.Content>
          </Card.Root>
        </Section>

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
