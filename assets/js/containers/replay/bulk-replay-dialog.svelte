<script lang="ts">
  import * as Dialog from "$lib/components/ui/dialog";
  import { Button } from "$lib/components/ui/button";
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import { Checkbox } from "$lib/components/ui/checkbox";
  import { router } from "@inertiajs/svelte";
  import { SearchIcon } from "lucide-svelte";

  type TopicItem = {
    id: string;
    name: string;
    description?: string;
  };

  type Props = {
    open: boolean;
    submitUrl: string;
    targetName?: string;
    topics: TopicItem[];
  };

  let {
    open = $bindable(false),
    submitUrl,
    targetName = "endpoint",
    topics = [],
  }: Props = $props();

  const toLocalISO = (d: Date) => {
    const pad = (n: number) => String(n).padStart(2, "0");
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(
      d.getHours(),
    )}:${pad(d.getMinutes())}`;
  };

  const defaultSince = toLocalISO(new Date(Date.now() - 30 * 60 * 1000));
  const defaultUntil = toLocalISO(new Date());

  let sinceValue = $state(defaultSince);
  let untilValue = $state(defaultUntil);
  let topicSearch = $state("");
  let selectedTopicIds = $state<Record<string, boolean>>({});
  let isSubmitting = $state(false);

  const filteredTopics = $derived(
    topics.filter(
      (t) =>
        t.name.toLowerCase().includes(topicSearch.toLowerCase()) ||
        (t.description &&
          t.description.toLowerCase().includes(topicSearch.toLowerCase())),
    ),
  );

  const selectedCount = $derived(
    Object.values(selectedTopicIds).filter(Boolean).length,
  );

  const allFilteredSelected = $derived(
    filteredTopics.length > 0 &&
      filteredTopics.every((t) => selectedTopicIds[t.id]),
  );

  const toggleSelectAll = (checked: boolean) => {
    const updated = { ...selectedTopicIds };
    for (const t of filteredTopics) {
      updated[t.id] = checked;
    }
    selectedTopicIds = updated;
  };

  const handleSubmit = () => {
    isSubmitting = true;
    const activeTopicIds = Object.keys(selectedTopicIds).filter(
      (id) => selectedTopicIds[id],
    );

    const payload: {
      since: string | null;
      until: string | null;
      topic_ids?: string[];
    } = {
      since: sinceValue ? new Date(sinceValue).toISOString() : null,
      until: untilValue ? new Date(untilValue).toISOString() : null,
    };

    if (activeTopicIds.length > 0) {
      payload.topic_ids = activeTopicIds;
    }

    router.post(submitUrl, payload, {
      preserveState: true,
      onFinish: () => {
        isSubmitting = false;
        open = false;
      },
    });
  };
</script>

<Dialog.Root bind:open>
  <Dialog.Content class="sm:max-w-lg">
    <Dialog.Header>
      <Dialog.Title>Bulk Replay Messages</Dialog.Title>
      <Dialog.Description class="text-xs text-muted-foreground">
        Replay messages on this {targetName} with the given filters. This will include
        messages that have already been sent successfully.
      </Dialog.Description>
    </Dialog.Header>

    <div class="flex flex-col gap-4 py-2">
      <div class="grid grid-cols-2 gap-4">
        <div class="flex flex-col gap-1.5">
          <Label for="since" class="text-xs font-semibold">Since</Label>
          <Input
            id="since"
            type="datetime-local"
            class="text-xs"
            bind:value={sinceValue}
          />
        </div>
        <div class="flex flex-col gap-1.5">
          <Label for="until" class="text-xs font-semibold">Until</Label>
          <Input
            id="until"
            type="datetime-local"
            class="text-xs"
            bind:value={untilValue}
          />
        </div>
      </div>

      <div class="flex flex-col gap-2">
        <Label class="text-xs font-semibold">Event Types (Topics)</Label>
        <div class="relative">
          <SearchIcon
            class="absolute left-2.5 top-2.5 size-3.5 text-muted-foreground"
          />
          <Input
            type="text"
            placeholder="Search topics..."
            class="pl-8 text-xs"
            bind:value={topicSearch}
          />
        </div>

        <div
          class="border rounded-md p-2 flex flex-col gap-1 max-h-48 overflow-y-auto bg-card"
        >
          {#if filteredTopics.length > 1}
            <div class="flex items-center gap-2 px-2 py-1.5 border-b mb-1">
              <Checkbox
                id="select-all-topics"
                checked={allFilteredSelected}
                onCheckedChange={(checked) => toggleSelectAll(!!checked)}
              />
              <label
                for="select-all-topics"
                class="text-xs font-medium cursor-pointer"
              >
                Select all
              </label>
            </div>
          {/if}

          {#if filteredTopics.length === 0}
            <p class="text-xs text-muted-foreground p-2 text-center">
              No matching topics found
            </p>
          {:else}
            {#each filteredTopics as topic (topic.id)}
              <label
                class="flex items-start gap-2.5 px-2 py-1.5 rounded-sm hover:bg-muted/50 cursor-pointer"
              >
                <Checkbox
                  checked={!!selectedTopicIds[topic.id]}
                  onCheckedChange={(checked) => {
                    selectedTopicIds[topic.id] = !!checked;
                  }}
                  class="mt-0.5"
                />
                <div class="flex flex-col">
                  <span class="text-xs font-mono font-medium">{topic.name}</span
                  >
                  {#if topic.description}
                    <span class="text-[11px] text-muted-foreground">
                      {topic.description}
                    </span>
                  {/if}
                </div>
              </label>
            {/each}
          {/if}
        </div>

        <p class="text-[11px] text-muted-foreground">
          {#if selectedCount === 0}
            Using all event types. Select from the above list to filter.
          {:else}
            Filtering by {selectedCount} selected topic{selectedCount === 1
              ? ""
              : "s"}.
          {/if}
        </p>
      </div>
    </div>

    <Dialog.Footer class="flex justify-end gap-2 pt-2">
      <Button
        variant="outline"
        onclick={() => (open = false)}
        disabled={isSubmitting}
      >
        Cancel
      </Button>
      <Button onclick={handleSubmit} disabled={isSubmitting}>
        {isSubmitting ? "Replaying..." : "Replay"}
      </Button>
    </Dialog.Footer>
  </Dialog.Content>
</Dialog.Root>
