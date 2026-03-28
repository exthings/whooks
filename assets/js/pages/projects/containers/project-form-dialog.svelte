<script lang="ts">
  import type { Topic } from "$types";

  import { Input } from "$lib/components/ui/input";
  import { Textarea } from "$lib/components/ui/textarea";
  import { Label } from "$lib/components/ui/label";
  import { Button } from "$lib/components/ui/button";

  import * as ToggleGroup from "$lib/components/ui/toggle-group";
  import * as Dialog from "$lib/components/ui/dialog/index.js";

  type Props = {
    open: boolean;
  };

  let { open = $bindable(false) }: Props = $props();
</script>

<Dialog.Root bind:open>
  <Dialog.Content>
    <Dialog.Header>
      <Dialog.Title>Create topic</Dialog.Title>
    </Dialog.Header>
    <form>
      <div class="flex flex-col gap-4">
        <div class="grid gap-2">
          <Label for="name" class="text-end">Name</Label>
          <Input id="name" />
        </div>
        <div class="grid gap-2">
          <Label for="uid" class="text-end">UID</Label>
          <Input id="uid" />
        </div>
        <div class="grid gap-2">
          <Label for="status" class="text-end">Status</Label>
          <ToggleGroup.Root variant="outline" type="single" value="enabled">
            <ToggleGroup.Item value="enabled">Enabled</ToggleGroup.Item>
            <ToggleGroup.Item value="disabled">Disabled</ToggleGroup.Item>
          </ToggleGroup.Root>
        </div>
        <div class="grid gap-2">
          <Label for="metadata" class="text-end">Metadata</Label>
          <Textarea id="metadata" />
        </div>
      </div>
    </form>
  </Dialog.Content>
</Dialog.Root>
