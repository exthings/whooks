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
  };

  let { open = $bindable(false) }: Props = $props();

  const form = useForm<Form>({
    name: "",
  });

  const submit = (e: Event) => {
    e.preventDefault();
    $form.post("/ui/admin/organizations", {
      preserveScroll: true,
      preserveState: true,
      only: ["errors", "project"],
      onSuccess: () => {
        open = false;
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
          <Label for="name" class="text-end">Name</Label>
          <Input id="name" name="name" bind:value={$form.name} required />
          {#if $form.errors.name}
            <p class="text-red-500">{$form.errors.name}</p>
          {/if}
        </div>
        <div class="flex justify-end gap-2">
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
