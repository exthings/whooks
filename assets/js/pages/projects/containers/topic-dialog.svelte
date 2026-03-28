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

  import DateTimeDisplay from "$components/date-time-display.svelte";
  import JsonSchemaViewer from "$components/json-schema-viewer.svelte";

  import * as Dialog from "$lib/components/ui/dialog/index.js";

  type Props = {
    topic: Topic | null;
  };

  let { topic = null }: Props = $props();

  let topicDialogIsOpen = $derived(topic !== null);
</script>

<Dialog.Root
  open={topicDialogIsOpen}
  onOpenChange={(value: boolean) => {
    topic = null;
  }}
>
  <Dialog.Content class="sm:max-w-4xl">
    <Dialog.Header>
      <Dialog.Title>Topic - {topic?.name}</Dialog.Title>
      <Dialog.Description>
        {topic?.description}
      </Dialog.Description>
    </Dialog.Header>
    <div class="flex flex-col gap-4">
      {#if topic}
        <dl class="text-sm grid grid-cols-2 gap-4">
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">ID</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              {topic.id}
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Name</dt>
            <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
              {topic.name}
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Inserted at</dt>
            <dd class="text-gray-700 sm:col-span-3">
              <DateTimeDisplay
                value={topic.insertedAt}
                size="xs"
                options={{ fractionalSecondDigits: undefined }}
              />
            </dd>
          </div>
          <div class="flex flex-col gap-1">
            <dt class="text-xs font-semibold">Updated at</dt>
            <dd class="text-gray-700 sm:col-span-3">
              <DateTimeDisplay
                value={topic.updatedAt}
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
                <JsonSchemaViewer schema={topic.jsonSchema} />
              </Card.Content>
            </Card.Root>
          </div>
          <div class="flex flex-col">
            <h3 class=" font-semibold pb-2">Example</h3>
            <Card.Root class="shadow-none py-2 flex-1">
              <Card.Content>
                <andypf-json-viewer data={topic.example}></andypf-json-viewer>
              </Card.Content>
            </Card.Root>
          </div>
        </div>
      {/if}
    </div>
  </Dialog.Content>
</Dialog.Root>
