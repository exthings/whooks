<script lang="ts">
  import * as Sheet from "$lib/components/ui/sheet";
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import { Button } from "$lib/components/ui/button";
  import { Form } from "@inertiajs/svelte";

  type Props = {
    open: boolean;
  };

  let { open = $bindable() }: Props = $props();
</script>

<Sheet.Root bind:open>
  <Sheet.Content side="right">
    <Sheet.Header>
      <Sheet.Title>Create consumer</Sheet.Title>
    </Sheet.Header>
    <Form
      class="grid flex-1 auto-rows-min gap-6 px-4"
      method="post"
      action="/ui/admin/consumers"
      onSuccess={() => (open = false)}
    >
      {#snippet children({ errors })}
        <div class="grid gap-2">
          <Label for="uid" class="text-end">Unique ID</Label>
          <Input id="uid" name="uid" />
          {#if errors["uid"]}
            <p class="text-red-500 text-sm">{errors["uid"]}</p>
          {/if}
        </div>
        <div class="grid gap-2">
          <Label for="name" class="text-end">Name</Label>
          <Input id="name" name="name" />
          {#if errors["name"]}
            <p class="text-red-500 text-sm">{errors["name"]}</p>
          {/if}
        </div>
        <Button type="submit">Create</Button>
      {/snippet}
    </Form>
  </Sheet.Content>
</Sheet.Root>
