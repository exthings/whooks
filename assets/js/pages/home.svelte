<script lang="ts">
  import * as Empty from "$lib/components/ui/empty/index.js";
  import * as Alert from "$lib/components/ui/alert/index.js";
  import { Button } from "$lib/components/ui/button/index.js";
  import { Building2Icon, SquareArrowLeftIcon } from "lucide-svelte";
  import { PersistedState } from "runed";

  let { organizations } = $props();

  let organization = new PersistedState<string | null>("organization", null);
</script>

{#if organizations.data.length === 0}
  <Empty.Root class="h-[calc(100vh-1rem)]">
    <Empty.Header>
      <Empty.Media variant="icon">
        <Building2Icon />
      </Empty.Media>
      <Empty.Title class="text-2xl">No organization yet</Empty.Title>
      <Empty.Description class="text-md">
        You haven't created any organization yet.
        <br />
        Get started by creating your first organization.
      </Empty.Description>
    </Empty.Header>
    <Empty.Content>
      <div class="flex gap-2">
        <Button>Create organization</Button>
      </div>
    </Empty.Content>
  </Empty.Root>
{:else if organization.current === null}
  <Empty.Root class="h-[calc(100vh-1rem)]">
    <Empty.Header>
      <Empty.Media variant="icon">
        <Building2Icon />
      </Empty.Media>
      <Empty.Title class="text-2xl">No organization selected</Empty.Title>
      <Empty.Description class="text-md">
        You haven't selected any organization yet.
      </Empty.Description>
    </Empty.Header>
    <Empty.Content class="text-left">
      <Alert.Root>
        <SquareArrowLeftIcon />
        <Alert.Title>Select an organization on sidebar.</Alert.Title>
      </Alert.Root>
    </Empty.Content>
  </Empty.Root>
{/if}
