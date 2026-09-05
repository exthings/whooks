<script lang="ts" module>
  export { default as layout } from "$layouts/portal.svelte";
</script>

<script lang="ts">
  import type { Project, Event, Topic, Meta } from "$types";

  import { Deferred, router } from "@inertiajs/svelte";
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
  import EventsTable from "$components/events-table.svelte";
  import TopicDialog from "$components/topic-dialog.svelte";
  import { getFilterValue } from "$utils";
  import { useDebounce } from "runed";
  import { EllipsisIcon, EyeIcon, PlusIcon } from "lucide-svelte";

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
  };

  const { id, projects, project, events, subscriptions }: Props = $props();

  let searchName = $derived(
    getFilterValue(projects.meta.filters, "name")[0]?.value,
  );

  let selectedTopic = $state<Topic | null>(null);
</script>

<svelte:head>
  {#if project}
    <title>Project - {project.name}</title>
  {:else}
    <title>Projects</title>
  {/if}
</svelte:head>

{#snippet sidebar()}
  <SidebarHeader title="Projects" searchValue={searchName} />

  <div class="grow overflow-y-scroll">
    <div class="flex flex-col">
      {#each projects.data as project (project.id)}
        <SidebarItem
          label={project.name}
          href={id ? `${project.id}` : `projects/${project.id}`}
          only={["id", "project", "events", "subscriptions"]}
          isActive={id === project.id}
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
  <div class="px-8 py-6 flex-1 flex flex-col gap-6 overflow-x-scroll">
    {#key id}
      {#if project}
        <header>
          <div class="flex justify-between">
            <div class="flex items-center gap-2 min-h-10">
              <h1 class="text-xl font-semibold">{project.name}</h1>
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
            </dl>
          </div>
        </header>

        <Tabs.Root value="overview">
          <Tabs.List>
            <Tabs.Trigger value="overview">Overview</Tabs.Trigger>
            <Tabs.Trigger value="metrics">Metrics</Tabs.Trigger>
          </Tabs.List>
          <Tabs.Content value="overview" class="flex flex-col gap-6">
            <Section title="Topics" actions={topicsActions}>
              <Card.Root class="shadow-none py-0 px-0 p-0 gap-1">
                <Card.Content class="p-0">
                  <ul class="flex flex-col divide-y divide-gray-200">
                    {#each project.topics as topic (topic.id)}
                      <li class="flex items-center justify-between py-2 px-4">
                        <div>
                          <div class="flex items-center gap-2">
                            <p class="font-mono text-sm">{topic.name}</p>
                            <span
                              class="text-xs bg-gray-200 rounded px-1.5 py-0.5"
                            >
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
          </Tabs.Content>
          <Tabs.Content value="metrics">Working in progress.</Tabs.Content>
        </Tabs.Root>
      {/if}
    {/key}
  </div>
</ContentWithSidebar>

<TopicDialog topic={selectedTopic} showDetails={false} />
