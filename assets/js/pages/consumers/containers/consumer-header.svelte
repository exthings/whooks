<script lang="ts">
  import type { Consumer } from "$types";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import { Button } from "$lib/components/ui/button";
  import * as DropdownMenu from "$lib/components/ui/dropdown-menu";
  import { EllipsisIcon } from "lucide-svelte";
  import {
    ReplayDropdown,
    RecoverFailedDialog,
    BulkReplayDialog,
  } from "$containers/replay";
  import { buildHref } from "$utils";

  type Props = {
    consumer: Consumer;
    onCreatePortalLink: () => void;
  };

  const { consumer, onCreatePortalLink }: Props = $props();

  let showPortalLinkDialog = $state(false);
  let recoverFailedOpen = $state(false);
  let bulkReplayOpen = $state(false);
</script>

<header>
  <div class="flex items-center justify-between">
    <h1 class="text-xl font-semibold">{consumer.name}</h1>
    <div class="flex items-center gap-2">
      <ReplayDropdown
        showReplayMissing={false}
        onRecoverFailed={() => (recoverFailedOpen = true)}
        onBulkReplay={() => (bulkReplayOpen = true)}
      />
      <DropdownMenu.Root>
        <DropdownMenu.Trigger>
          <Button variant="outline" size="icon">
            <EllipsisIcon />
          </Button>
        </DropdownMenu.Trigger>
        <DropdownMenu.Content align="end">
          <DropdownMenu.Group>
            <DropdownMenu.Item onclick={onCreatePortalLink}>
              Portal link
            </DropdownMenu.Item>
            <DropdownMenu.Item>Edit</DropdownMenu.Item>
            <DropdownMenu.Item>Disable</DropdownMenu.Item>
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

{#if consumer}
  <RecoverFailedDialog
    bind:open={recoverFailedOpen}
    consumerId={consumer.id}
    targetName="consumer"
  />

  <BulkReplayDialog
    bind:open={bulkReplayOpen}
    submitUrl={buildHref(`/consumers/${consumer.id}/bulk-replay`)}
    targetName="consumer"
    topics={[]}
  />
{/if}
