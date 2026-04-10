<script lang="ts">
  import type {
    Event,
    Topic,
    Consumer,
    Project,
    Attempt,
    Endpoint,
  } from "$types";
  import ContentWithSidebar from "$components/content-with-sidebar.svelte";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import BadgeStatus from "$components/badge-status.svelte";
  import * as DropdownMenu from "$lib/components/ui/dropdown-menu";
  import { Button } from "$lib/components/ui/button";
  import { Badge } from "$lib/components/ui/badge";
  import CellTags from "$components/cell-tags.svelte";
  import * as Tabs from "$lib/components/ui/tabs";
  import { cn } from "$lib/utils";

  import {
    EllipsisVerticalIcon,
    BoxIcon,
    InboxIcon,
    ForwardIcon,
  } from "lucide-svelte";
  import { router } from "@inertiajs/svelte";

  type AttemptWithEndpoint = Attempt & { endpoint: Endpoint };

  type Props = {
    event: Event & {
      topic: Topic;
      consumer: Consumer;
      project: Project;
      attempts: AttemptWithEndpoint[];
    };
  };

  let { event }: Props = $props();

  let selectedAttempt = $derived<AttemptWithEndpoint | null>(
    event.attempts?.[0],
  );

  const statusVariant = $derived(
    {
      pending: "warning",
      scheduled: "secondary",
      processing: "info",
      retry: "secondary",
      success: "success",
      failed: "destructive",
    }[event.status],
  );

  const resend = () => {
    router.post(`${event.id}/resend`, {});
  };
</script>

<svelte:head>
  <title>Event - {event.id.slice(event.id.length - 6)}</title>
</svelte:head>

<ContentWithSidebar>
  <div class="px-8 py-6 flex flex-col gap-8 flex-1 overflow-x-scroll">
    <header class="flex flex-col gap-4">
      <div class="flex items-start justify-between">
        <div class="flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <h1 class="text-lg font-semibold">Event</h1>
            <BadgeStatus variant={statusVariant} label={event.status} />
          </div>
          <p class="text-sm font-mono text-muted-foreground">{event.id}</p>
        </div>
        <div>
          <DropdownMenu.Root>
            <DropdownMenu.Trigger>
              {#snippet child({ props })}
                <Button {...props} variant="outline">
                  <EllipsisVerticalIcon />
                </Button>
              {/snippet}
            </DropdownMenu.Trigger>
            <DropdownMenu.Content class="w-56" align="end">
              <DropdownMenu.Group>
                <DropdownMenu.Item onclick={resend}
                  ><ForwardIcon />Resend</DropdownMenu.Item
                >
              </DropdownMenu.Group>
            </DropdownMenu.Content>
          </DropdownMenu.Root>
        </div>
      </div>
      <div class="w-full">
        <dl class="text-sm grid grid-cols-4 gap-4">
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">ID</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              {event.id}
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">UID</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              {event.uid || "-"}
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Inserted at</dt>
            <dd class="text-gray-700 sm:col-span-3">
              <DateTimeDisplay
                value={event.insertedAt}
                size="xs"
                options={{ fractionalSecondDigits: 3 }}
              />
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Updated at</dt>
            <dd class="text-gray-700 sm:col-span-3">
              <DateTimeDisplay
                value={event.updatedAt}
                size="xs"
                options={{ fractionalSecondDigits: 3 }}
              />
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Consumer</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              <Badge variant="outline">
                <InboxIcon />
                {event.consumer.name}</Badge
              >
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Project</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              <Badge variant="outline"><BoxIcon />{event.project.name}</Badge>
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Topic</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              <Badge variant="outline">
                <BoxIcon />
                {event.topic.name}
              </Badge>
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Tags</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              <CellTags tags={event.tags} />
            </dd>
          </div>
        </dl>
      </div>
    </header>

    <div class="grid grid-cols-6 border rounded-lg flex-1">
      <div class="col-span-3 divide-y">
        <div class="grid grid-cols-12 px-3 py-2 text-sm font-semibold">
          <span class="col-span-2">Status</span>
          <span class="col-span-3">Timestamp</span>
          <span class="col-span-7">URL</span>
        </div>
        {#each event.attempts as attempt}
          <button
            class={cn(
              "grid grid-cols-12 py-2 px-3 cursor-pointer hover:bg-muted text-left w-full",
              selectedAttempt?.id === attempt.id && "bg-muted",
            )}
            onclick={() => (selectedAttempt = attempt)}
            type="button"
          >
            <div class="col-span-2">
              <BadgeStatus
                variant={attempt.status === "success"
                  ? "success"
                  : "destructive"}
                label={attempt.status}
              />
            </div>
            <div class="col-span-3">
              <DateTimeDisplay
                value={attempt.insertedAt}
                size="xs"
                options={{ fractionalSecondDigits: undefined }}
              />
            </div>
            <div class="col-span-7">
              <span class="text-xs font-mono text-muted-foreground"
                >{attempt.endpoint.url}</span
              >
            </div>
          </button>
        {/each}
      </div>

      <div class="col-span-3 border-l pt-2">
        {#if selectedAttempt}
          <div class="flex flex-col">
            <div class="px-4">
              <div class="flex items-center gap-4 pb-1">
                <h3 class="font-semibold">Attempt</h3>
                <BadgeStatus
                  variant={selectedAttempt.status === "success"
                    ? "success"
                    : "destructive"}
                  label={selectedAttempt.status}
                />
              </div>
              <p class="text-xs font-mono text-muted-foreground pb-1">
                {selectedAttempt.id}
              </p>
              <div class="flex gap-1 pb-4">
                <dt class="text-xs font-semibold">URL</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {selectedAttempt.endpoint.url}
                </dd>
              </div>
            </div>
            <dl class="text-sm grid grid-cols-3 gap-4 px-4 pb-6">
              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Timestamp</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  <DateTimeDisplay value={selectedAttempt.insertedAt} />
                </dd>
              </div>

              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">Latency</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {selectedAttempt.latencyMs}ms
                </dd>
              </div>

              <div class="flex flex-col gap-1">
                <dt class="text-xs font-semibold">HTTP status</dt>
                <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
                  {selectedAttempt.resStatus}
                </dd>
              </div>
            </dl>

            <div class="px-4">
              <Tabs.Root value="request">
                <Tabs.List>
                  <Tabs.Trigger value="request">Request</Tabs.Trigger>
                  <Tabs.Trigger value="response">Response</Tabs.Trigger>
                </Tabs.List>
                <Tabs.Content value="request">
                  <div class="pb-4">
                    <div class="py-2 px-4">
                      <p class="text-xs font-mono font-semibold">Headers</p>
                      <andypf-json-viewer data={selectedAttempt.reqHeaders}
                      ></andypf-json-viewer>
                    </div>
                    <div class="py-2 px-4">
                      <p class="text-xs font-mono font-semibold">Body</p>
                      <andypf-json-viewer data={event.data}
                      ></andypf-json-viewer>
                    </div>
                  </div>
                </Tabs.Content>
                <Tabs.Content value="response">
                  <div class="pb-4">
                    <div class="py-2 px-4">
                      <p class="text-xs font-mono font-semibold">Headers</p>
                      <andypf-json-viewer data={selectedAttempt.resHeaders}
                      ></andypf-json-viewer>
                    </div>
                    <div class="py-2 px-4">
                      <p class="text-xs font-mono font-semibold">Body</p>
                      <andypf-json-viewer data={selectedAttempt.resBody}
                      ></andypf-json-viewer>
                    </div>
                  </div>
                </Tabs.Content>
              </Tabs.Root>
            </div>
          </div>
        {/if}
      </div>
    </div>
  </div>
</ContentWithSidebar>
