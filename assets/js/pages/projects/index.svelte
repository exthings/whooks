<script lang="ts">
  import type { Project, Event, Topic, Meta } from "$types";

  import { Deferred, router } from "@inertiajs/svelte";
  import * as Sheet from "$lib/components/ui/sheet";
  import BadgeStatus from "$components/badge-status.svelte";
  import type { BadgeStatusVariant } from "$components/badge-status.svelte";
  import { Input } from "$lib/components/ui/input";
  import { Textarea } from "$lib/components/ui/textarea";
  import { Label } from "$lib/components/ui/label";
  import { Button } from "$lib/components/ui/button";
  import * as Tabs from "$lib/components/ui/tabs";
  import * as Card from "$lib/components/ui/card";

  import Section from "$components/section.svelte";
  import ContentWithSidebar from "$components/content-with-sidebar.svelte";
  import SidebarHeader from "$components/sidebar-header.svelte";
  import SidebarItem from "$components/sidebar-item.svelte";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import EventsTable from "$components/events-table.svelte";
  import { getFilterValue } from "$utils";
  import { useDebounce } from "runed";
  import { EllipsisIcon, EyeIcon, PlusIcon } from "lucide-svelte";
  import JsonSchemaViewer from "$components/json-schema-viewer.svelte";

  import * as Dialog from "$lib/components/ui/dialog/index.js";

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

  const STATUS_MAP: Record<Project["status"], BadgeStatusVariant> = {
    enabled: "success",
    disabled: "destructive",
  };

  let searchName = $derived(
    getFilterValue(projects.meta.filters, "name")[0]?.value,
  );

  let formIsOpen = $state(false);

  let selectedTopic = $state<Topic | null>(null);
  let topicDialogIsOpen = $derived(selectedTopic !== null);

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
    onCreate={() => (formIsOpen = true)}
    onSearch={handleSearch}
    searchValue={searchName}
  />

  <div class="grow overflow-y-scroll">
    <div class="flex flex-col">
      {#each projects.data as project (project.id)}
        <SidebarItem
          href={`/ui/admin/projects/${project.id}`}
          only={["id", "project", "events", "subscriptions"]}
          isActive={id === project.id}
          label={project.name}
          description={project.organization.name}
          data={{ filters: projects.meta.filters }}
          preserveState={true}
          preserveScroll={true}
        />
      {/each}
    </div>
  </div>
{/snippet}

{#snippet topicsActions()}
  <Button variant="outline" size="icon"><PlusIcon /></Button>
{/snippet}

<ContentWithSidebar {sidebar}>
  <div class="px-8 py-6 flex-1 flex flex-col gap-6 overflow-x-scroll">
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

        <Tabs.Root value="overview">
          <Tabs.List>
            <Tabs.Trigger value="overview">Overview</Tabs.Trigger>
            <Tabs.Trigger value="metrics">Metrics</Tabs.Trigger>
          </Tabs.List>
          <Tabs.Content value="overview" class="flex flex-col gap-6">
            <div class="grid grid-cols-4 gap-4">
              <Card.Root class="shadow-none py-4 gap-1">
                <Card.Header>
                  <Card.Title class="text-sm font-normal text-muted-foreground">
                    Subscribers
                  </Card.Title>
                </Card.Header>
                <Card.Content>
                  <Deferred data={["subscriptions"]}>
                    {#snippet fallback()}
                      Loading
                    {/snippet}
                    {#if subscriptions}
                      <p class="text-3xl">
                        {subscriptions.reduce((acc, sub) => acc + sub.count, 0)}
                      </p>
                    {/if}
                  </Deferred>
                </Card.Content>
              </Card.Root>

              <Card.Root class="shadow-none py-4 gap-1">
                <Card.Header>
                  <Card.Title class="text-sm font-normal text-muted-foreground">
                    Events
                  </Card.Title>
                </Card.Header>
                <Card.Content>
                  <p class="text-3xl">{events?.meta.total_count ?? 0}</p>
                </Card.Content>
              </Card.Root>
            </div>

            <Section title="Topics" actions={topicsActions}>
              <Card.Root
                class="shadow-none py-0 px-0 p-0 gap-1 overflow-x-scroll"
              >
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

<Sheet.Root bind:open={formIsOpen}>
  <Sheet.Content side="right" class="">
    <Sheet.Header>
      <Sheet.Title>Create project</Sheet.Title>
    </Sheet.Header>
    <div class="grid flex-1 auto-rows-min gap-6 px-4">
      <div class="grid gap-2">
        <Label for="name" class="text-end">Name</Label>
        <Input id="name" />
      </div>
      <div class="grid gap-2">
        <Label for="uid" class="text-end">UID</Label>
        <Input id="uid" />
      </div>
    </div>
    <Sheet.Footer>
      <Button type="submit">Create</Button>
    </Sheet.Footer>
  </Sheet.Content>
</Sheet.Root>

<Dialog.Root
  open={topicDialogIsOpen}
  onOpenChange={(value: boolean) => {
    selectedTopic = null;
  }}
>
  <Dialog.Content class="sm:max-w-4xl">
    <Dialog.Header>
      <Dialog.Title>Topic - {selectedTopic?.name}</Dialog.Title>
      <Dialog.Description>
        {selectedTopic?.description}
      </Dialog.Description>
    </Dialog.Header>
    <div class="flex flex-col gap-4">
      {#if selectedTopic}
        <dl class="text-sm grid grid-cols-2 gap-4">
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">ID</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              {selectedTopic.id}
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Name</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              {selectedTopic.name}
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Inserted at</dt>
            <dd class="text-gray-700 sm:col-span-3">
              <DateTimeDisplay
                value={selectedTopic.insertedAt}
                size="xs"
                options={{ fractionalSecondDigits: undefined }}
              />
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Updated at</dt>
            <dd class="text-gray-700 sm:col-span-3">
              <DateTimeDisplay
                value={selectedTopic.updatedAt}
                size="xs"
                options={{ fractionalSecondDigits: undefined }}
              />
            </dd>
          </div>
        </dl>
        <div class="grid grid-cols-2 gap-4">
          <div class="flex flex-col">
            <h3 class=" font-semibold pb-2">JSON Schema</h3>
            <Card.Root class="shadow-none py-2 flex-1">
              <Card.Content>
                <JsonSchemaViewer schema={selectedTopic.jsonSchema} />
              </Card.Content>
            </Card.Root>
          </div>
          <div class="flex flex-col">
            <h3 class=" font-semibold pb-2">Example</h3>
            <Card.Root class="shadow-none py-2 flex-1">
              <Card.Content>
                <andypf-json-viewer data={selectedTopic.example}
                ></andypf-json-viewer>
              </Card.Content>
            </Card.Root>
          </div>
        </div>
      {/if}
    </div>
  </Dialog.Content>
</Dialog.Root>

<Dialog.Root open={false}>
  <Dialog.Content>
    <Dialog.Header>
      <Dialog.Title>Create topic</Dialog.Title>
    </Dialog.Header>
    <form>
      <div class="flex flex-col gap-4">
        <div class="grid gap-2">
          <Label for="name" class="text-end">Name</Label>
          <Input id="name" />
        </div>
        <div class="grid gap-2">
          <Label for="description" class="text-end">Description</Label>
          <Textarea id="description" />
        </div>
      </div>
    </form>
  </Dialog.Content>
</Dialog.Root>
