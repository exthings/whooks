<script lang="ts">
  import { useForm } from "@inertiajs/svelte";
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import { Button } from "$lib/components/ui/button";

  import * as Dialog from "$lib/components/ui/dialog/index.js";

  type Props = {
    open: boolean;
  };

  type Form = {
    name: string;
    event_retention_days: number | string | null;
  };

  let { open = $bindable(false) }: Props = $props();

  const form = useForm<Form>({
    name: "",
    event_retention_days: null,
  });

  const submit = (e: Event) => {
    e.preventDefault();
    $form.post("/ui/admin/organizations", {
      preserveScroll: true,
      preserveState: true,
      only: ["errors", "project"],
      onSuccess: () => {
        open = false;
        $form.reset();
      },
    });
  };
</script>

<Dialog.Root bind:open>
  <Dialog.Content>
    <Dialog.Header>
      <Dialog.Title>Create organization</Dialog.Title>
    </Dialog.Header>
    <form onsubmit={submit}>
      <div class="flex flex-col gap-4">
        <div class="grid gap-2">
          <Label for="name">Name</Label>
          <Input id="name" name="name" bind:value={$form.name} required />
          {#if $form.errors.name}
            <p class="text-red-500 text-xs">{$form.errors.name}</p>
          {/if}
        </div>

        <div class="grid gap-2">
          <Label for="event_retention_days">Event retention (days)</Label>
          <Input
            id="event_retention_days"
            name="event_retention_days"
            type="number"
            min="1"
            placeholder="e.g. 30 (optional)"
            bind:value={$form.event_retention_days}
          />
          <p class="text-xs text-muted-foreground">
            Number of days to retain events. Leave blank for indefinite retention.
          </p>
          {#if $form.errors.event_retention_days}
            <p class="text-red-500 text-xs">{$form.errors.event_retention_days}</p>
          {/if}
        </div>

        <div class="flex justify-end gap-2 mt-2">
          <Button
            type="button"
            variant="outline"
            onclick={() => (open = false)}
          >
            Cancel
          </Button>
          <Button type="submit">Create</Button>
        </div>
      </div>
    </form>
  </Dialog.Content>
</Dialog.Root>
