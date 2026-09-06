<script lang="ts">
  import type { Organization } from "$types/organization";
  import { useForm } from "@inertiajs/svelte";
  import {
    Field,
    FieldSet,
    FieldLegend,
    FieldDescription,
    FieldGroup,
    FieldLabel,
    FieldContent,
    FieldError,
    FieldSeparator,
  } from "$lib/components/ui/field";
  import { Switch } from "$lib/components/ui/switch";
  import { Input } from "$lib/components/ui/input";
  import { Button } from "$lib/components/ui/button";

  type Props = {
    organization: Organization;
  };

  let { organization }: Props = $props();

  type Form = {
    name: string;
    event_retention_days: number | string | null;
  };

  const rawRetention = $derived(
    organization.eventRetentionDays ??
      organization.event_retention_days ??
      null,
  );

  let retentionEnabled = $state(rawRetention !== null);

  const form = useForm<Form>({
    name: organization.name,
    event_retention_days: rawRetention,
  });

  const handleRetentionToggle = (checked: boolean) => {
    retentionEnabled = checked;
    if (checked) {
      if (!$form.event_retention_days) {
        $form.event_retention_days = rawRetention || 30;
      }
    } else {
      $form.event_retention_days = null;
    }
  };

  const submit = (e: Event) => {
    e.preventDefault();

    $form
      .transform((data) => ({
        ...data,
        event_retention_days: retentionEnabled
          ? $form.event_retention_days
          : null,
      }))
      .put(`/ui/admin/${organization.id}/settings`, {
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
    <h1 class="text-2xl font-bold tracking-tight">Organization settings</h1>
  </div>

  <form onsubmit={submit} class="flex flex-col gap-6">
    <FieldSet>
      <FieldLegend>General information</FieldLegend>
      <FieldDescription>
        The display ID and name of your organization.
      </FieldDescription>
      <FieldGroup>
        <Field>
          <FieldLabel for="org_id">ID</FieldLabel>
          <Input
            id="org_id"
            value={organization.id}
            disabled
            class="bg-muted"
          />
        </Field>
        <Field>
          <FieldLabel for="name">Name</FieldLabel>
          <Input id="name" name="name" bind:value={$form.name} required />
          {#if $form.errors.name}
            <FieldError>{$form.errors.name}</FieldError>
          {/if}
        </Field>
      </FieldGroup>
    </FieldSet>

    <FieldSeparator />

    <FieldSet>
      <FieldLegend>Event retention policy</FieldLegend>
      <FieldDescription>
        Configure how long events and delivery attempts are retained before
        being permanently deleted.
      </FieldDescription>
      <FieldGroup>
        <Field orientation="horizontal" class="items-center justify-between">
          <FieldContent>
            <FieldLabel for="event_retention_enabled"
              >Enable retention policy</FieldLabel
            >
            <FieldDescription>
              Automatically purge events and delivery attempts after a specified
              retention window.
            </FieldDescription>
          </FieldContent>
          <Switch
            id="event_retention_enabled"
            bind:checked={retentionEnabled}
            onCheckedChange={handleRetentionToggle}
          />
        </Field>

        {#if retentionEnabled}
          <Field>
            <FieldLabel for="event_retention_days"
              >Retention window (days)</FieldLabel
            >
            <Input
              id="event_retention_days"
              name="event_retention_days"
              type="number"
              min="1"
              placeholder="e.g. 30"
              bind:value={$form.event_retention_days}
              required
            />
            {#if $form.errors.event_retention_days}
              <FieldError>
                {$form.errors.event_retention_days}
              </FieldError>
            {/if}
          </Field>
        {/if}
      </FieldGroup>
    </FieldSet>

    <FieldSeparator />

    <div class="flex justify-end">
      <Button type="submit" disabled={$form.processing}>
        {$form.processing ? "Saving..." : "Save Changes"}
      </Button>
    </div>
  </form>
</div>
