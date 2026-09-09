<script lang="ts">
  import type { Topic } from "$types";
  import Section from "$components/section.svelte";
  import * as Card from "$lib/components/ui/card";
  import * as Empty from "$lib/components/ui/empty";
  import { Button } from "$lib/components/ui/button";
  import { EyeIcon, HashIcon, PlusIcon } from "lucide-svelte";

  type Subscriptions = {
    topicId: string;
    count: number;
  };

  type Props = {
    topics: Topic[];
    subscriptions?: Subscriptions[];
    onAddTopic: () => void;
    onViewTopic: (topic: Topic) => void;
  };

  const { topics, subscriptions, onAddTopic, onViewTopic }: Props = $props();
</script>

{#snippet topicsActions()}
  <Button variant="outline" size="icon" onclick={onAddTopic}>
    <PlusIcon />
  </Button>
{/snippet}

<Section title="Topics" actions={topicsActions}>
  <Card.Root class="shadow-none py-0 px-0 p-0 gap-1 overflow-x-scroll">
    <Card.Content class="p-0">
      {#if topics.length > 0}
        <ul class="flex flex-col divide-y divide-gray-200">
          {#each topics as topic (topic.id)}
            <li class="flex items-center justify-between py-2 px-4">
              <div>
                <div class="flex items-center gap-2">
                  <p class="font-mono text-sm">{topic.name}</p>
                  <span class="text-xs bg-gray-200 rounded px-1.5 py-0.5">
                    {subscriptions?.find((sub) => sub.topicId === topic.id)
                      ?.count ?? "-"}
                  </span>
                </div>
                <p class="text-muted-foreground text-xs">
                  {topic.description}
                </p>
              </div>
              <div>
                <Button
                  variant="outline"
                  size="sm"
                  onclick={() => onViewTopic(topic)}
                >
                  <EyeIcon />
                </Button>
              </div>
            </li>
          {/each}
        </ul>
      {:else}
        <Empty.Root class="border-none p-6">
          <Empty.Header class="gap-1.5 max-w-xs">
            <Empty.Media
              variant="icon"
              class="size-9 rounded-full bg-muted/80 text-muted-foreground ring-4 ring-muted/30 mb-1"
            >
              <HashIcon class="size-4" />
            </Empty.Media>
            <Empty.Title class="text-sm font-semibold text-foreground">
              No topics
            </Empty.Title>
            <Empty.Description class="text-xs text-muted-foreground">
              This project has no topics yet.
            </Empty.Description>
          </Empty.Header>
        </Empty.Root>
      {/if}
    </Card.Content>
  </Card.Root>
</Section>
