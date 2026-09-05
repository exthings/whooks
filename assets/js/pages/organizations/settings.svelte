<script lang="ts">
  import type { Organization } from "$types/organization";
  import { useForm } from "@inertiajs/svelte";
  import * as Card from "$lib/components/ui/card";
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import { Button } from "$lib/components/ui/button";

  type Props = {
    organization: Organization;
  };

  let { organization }: Props = $props();

  type Form = {
    name: string;
    event_retention_days: number | string | null;
  };

  // svelte-ignore state_referenced_locally
  const initialRetention =
    organization.eventRetentionDays ?? organization.event_retention_days ?? "";

  // svelte-ignore state_referenced_locally
  const form = useForm<Form>({
    name: organization.name,
    event_retention_days: initialRetention,
  });

  const submit = (e: Event) => {
    e.preventDefault();
    $form.put(`/ui/admin/${organization.id}/settings`, {
      preserveScroll: true,
      preserveState: true,
    });
  };
</script>

<svelte:head>
  <title>Settings - {organization.name}</title>
</svelte:head>

<div class="px-8 py-6 flex-1 flex flex-col gap-6 max-w-4xl">
  <div>
    <h1 class="text-2xl font-bold tracking-tight">Organization Settings</h1>
    <p class="text-sm text-muted-foreground mt-1">
      Manage your organization details and data retention policies.
    </p>
  </div>

  <form onsubmit={submit} class="flex flex-col gap-6">
    <Card.Root>
      <Card.Header>
        <Card.Title>General Information</Card.Title>
        <Card.Description>
          The display name and identity of your organization.
        </Card.Description>
      </Card.Header>
      <Card.Content class="space-y-4">
        <div class="grid gap-2">
          <Label for="name">Organization Name</Label>
          <Input id="name" name="name" bind:value={$form.name} required />
          {#if $form.errors.name}
            <p class="text-red-500 text-xs">{$form.errors.name}</p>
          {/if}
        </div>
        <div class="grid gap-2">
          <Label for="org_id">Organization ID</Label>
          <Input id="org_id" value={organization.id} disabled class="bg-muted" />
        </div>
      </Card.Content>
    </Card.Root>

    <Card.Root>
      <Card.Header>
        <Card.Title>Event Retention Policy</Card.Title>
        <Card.Description>
          Configure how long webhooks and delivery attempts are retained before being permanently deleted.
        </Card.Description>
      </Card.Header>
      <Card.Content class="space-y-4">
        <div class="grid gap-2">
          <Label for="event_retention_days">Retention Window (Days)</Label>
          <Input
            id="event_retention_days"
            name="event_retention_days"
            type="number"
            min="1"
            placeholder="e.g. 30 (Leave blank for indefinite retention)"
            bind:value={$form.event_retention_days}
          />
          <p class="text-xs text-muted-foreground">
            Webhooks older than this period and their delivery attempts will be automatically purged. Leave blank to retain indefinitely.
          </p>
          {#if $form.errors.event_retention_days}
            <p class="text-red-500 text-xs">{$form.errors.event_retention_days}</p>
          {/if}
        </div>
      </Card.Content>
      <Card.Footer class="flex justify-end border-t pt-4">
        <Button type="submit" disabled={$form.processing}>
          {$form.processing ? "Saving..." : "Save Changes"}
        </Button>
      </Card.Footer>
    </Card.Root>
  </form>
</div>
