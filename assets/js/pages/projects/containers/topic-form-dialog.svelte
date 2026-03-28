<script lang="ts">
  import type { Topic } from "$types";
  import { Form, useForm } from "@inertiajs/svelte";
  import { Input } from "$lib/components/ui/input";
  import { Textarea } from "$lib/components/ui/textarea";
  import { Label } from "$lib/components/ui/label";
  import * as ToggleGroup from "$lib/components/ui/toggle-group";
  import { Button } from "$lib/components/ui/button";

  import * as Dialog from "$lib/components/ui/dialog/index.js";

  type Props = {
    projectId: string;
    open: boolean;
  };

  type Form = {
    name: string;
    status: "enabled" | "disabled";
    description: string;
    jsonSchema: string;
    example: string;
  };

  let { projectId, open = $bindable(false) }: Props = $props();

  let status = $state("enabled");

  const form = useForm<Form>({
    name: "",
    description: "",
    jsonSchema: "",
    example: "",
    status: "enabled",
  });

  const parseToJson = (value: string | null | undefined) => {
    try {
      if (value) {
        return JSON.parse(value);
      }
      return null;
    } catch (error) {
      return null;
    }
  };

  const submit = (e: Event) => {
    e.preventDefault();
    $form
      .transform((data) => ({
        ...data,
        jsonSchema: parseToJson(data.jsonSchema),
        example: parseToJson(data.example),
        status,
        projectId,
      }))
      .post("/ui/admin/topics", {
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
      <Dialog.Title>Create topic</Dialog.Title>
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
        <div class="grid gap-2">
          <Label for="status" class="text-end">Status</Label>
          <ToggleGroup.Root
            variant="outline"
            type="single"
            bind:value={$form.status}
          >
            <ToggleGroup.Item value="enabled">Enabled</ToggleGroup.Item>
            <ToggleGroup.Item value="disabled">Disabled</ToggleGroup.Item>
          </ToggleGroup.Root>
          {#if $form.errors.status}
            <p class="text-red-500">{$form.errors.status}</p>
          {/if}
        </div>
        <div class="grid gap-2">
          <Label for="description" class="text-end">Description</Label>
          <Textarea
            id="description"
            name="description"
            bind:value={$form.description}
          />
          {#if $form.errors.description}
            <p class="text-red-500">{$form.errors.description}</p>
          {/if}
        </div>
        <div class="grid gap-2">
          <Label for="jsonSchema" class="text-end">JSON Schema</Label>
          <Textarea
            id="jsonSchema"
            name="jsonSchema"
            bind:value={$form.jsonSchema}
          />
          {#if $form.errors.jsonSchema}
            <p class="text-red-500">{$form.errors.jsonSchema}</p>
          {/if}
        </div>
        <div class="grid gap-2">
          <Label for="example" class="text-end">Example</Label>
          <Textarea id="example" name="example" bind:value={$form.example} />
          {#if $form.errors.example}
            <p class="text-red-500">{$form.errors.example}</p>
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
