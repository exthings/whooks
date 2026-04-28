<script lang="ts">
  import type { User } from "$types";
  import { useForm } from "@inertiajs/svelte";
  import { Input } from "$lib/components/ui/input";
  import * as RadioGroup from "$lib/components/ui/radio-group";
  import { Label } from "$lib/components/ui/label";
  import { Button } from "$lib/components/ui/button";

  import * as Dialog from "$lib/components/ui/dialog";

  type Form = Pick<User, "id" | "name" | "email" | "role">;

  type Props = {
    data?: Form;
    open: boolean;
  };

  const initialData: Form = {
    id: "",
    name: "",
    email: "",
    role: "root",
  };

  let { data = initialData, open = $bindable(false) }: Props = $props();

  const form = $derived(useForm<Form>(data));

  const submit = (e: Event) => {
    e.preventDefault();
    $form.put(`/ui/admin/settings/users/${data.id}`, {
      preserveScroll: true,
      preserveState: true,
      onSuccess: () => {
        open = false;
      },
    });
  };

  $inspect($form);
</script>

<Dialog.Root bind:open>
  <Dialog.Content>
    <Dialog.Header>
      <Dialog.Title>Create user</Dialog.Title>
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

        <RadioGroup.Root bind:value={$form.role}>
          <div class="flex items-center space-x-2">
            <RadioGroup.Item value="root" id="root" />
            <Label for="root" class="grid gap-2">
              <span>Root</span>
              <p class="text-muted-foreground text-sm">
                Root users can do everything.
              </p>
            </Label>
          </div>
          <div class="flex items-center space-x-2">
            <RadioGroup.Item value="admin" id="admin" />
            <Label for="admin" class="grid gap-2">
              <span>Admin</span>
              <p class="text-muted-foreground text-sm">
                Admins can do everything except create organizations.
              </p>
            </Label>
          </div>
          <div class="flex items-center space-x-2">
            <RadioGroup.Item value="support" id="support" />
            <Label for="support" class="grid gap-2">
              <span>Support</span>
              <p class="text-muted-foreground text-sm">
                Support users can only view projects, consumers and events.
              </p>
            </Label>
          </div>
        </RadioGroup.Root>

        <div class="text-xs">
          {JSON.stringify($form.errors)}
        </div>

        <div class="flex justify-end gap-2">
          <Button
            type="button"
            variant="outline"
            onclick={() => (open = false)}
          >
            Cancel
          </Button>
          <Button type="submit">Update</Button>
        </div>
      </div>
    </form>
  </Dialog.Content>
</Dialog.Root>
