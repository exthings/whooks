<script lang="ts">
  import type { Topic } from "$types";

  import BadgeStatus from "$components/badge-status.svelte";
  import * as Card from "$lib/components/ui/card";

  import DateTimeDisplay from "$components/date-time-display.svelte";
  import JsonSchemaViewer from "$components/json-schema-viewer.svelte";

  import * as Dialog from "$lib/components/ui/dialog/index.js";

  type Props = {
    topic: Topic | null;
    showDetails?: boolean;
  };

  let { topic = null, showDetails = true }: Props = $props();

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
      <Dialog.Title>Topic</Dialog.Title>
      <Dialog.Description>
        <div class="flex items-center gap-2">
          <span class="font-mono font-semibold text-black">{topic?.name}</span>
        </div>
        <span>{topic?.description}</span>
      </Dialog.Description>
    </Dialog.Header>
    <div class="flex flex-col gap-4">
      {#if topic}
        {#if showDetails}
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
        {/if}
        <div class="grid grid-cols-2 gap-4">
          <div class="flex flex-col">
            <div class="flex gap-2 items-center mb-2">
              <h3 class=" font-semibold">JSON Schema</h3>
              {#if topic.validateSchema}
                <BadgeStatus variant="success" size="xs" label="enabled" />
              {:else}
                <BadgeStatus variant="warning" size="xs" label="disabled" />
              {/if}
            </div>
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
