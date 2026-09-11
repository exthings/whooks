<script lang="ts">
  import * as Dialog from "$lib/components/ui/dialog";
  import { Button } from "$lib/components/ui/button";
  import { router, page } from "@inertiajs/svelte";

  type Props = {
    open: boolean;
    endpointId?: string;
    projectId?: string;
    targetName?: string;
  };

  let {
    open = $bindable(false),
    endpointId,
    projectId,
    targetName = "endpoint",
  }: Props = $props();

  let selectedTimeframe = $state("8h");
  let isSubmitting = $state(false);

  const orgId = $derived(
    $page.props.organizationId || $page.params.organization_id || "",
  );

  const submitUrl = $derived(
    endpointId
      ? `/ui/admin/${orgId}/endpoints/${endpointId}/recover-failed`
      : `/ui/admin/${orgId}/projects/${projectId}/recover-failed`,
  );

  const formatSub = (msAgo: number) => {
    const d = new Date(Date.now() - msAgo);
    return `Since ${d.toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
      year: "numeric",
    })} at ${d.toLocaleTimeString(undefined, {
      hour: "numeric",
      minute: "2-digit",
    })}`;
  };

  const options = $derived([
    {
      id: "8h",
      title: "8 hours ago",
      subtitle: formatSub(8 * 60 * 60 * 1000),
      ms: 8 * 60 * 60 * 1000,
    },
    {
      id: "yesterday",
      title: "Yesterday",
      subtitle: formatSub(24 * 60 * 60 * 1000),
      ms: 24 * 60 * 60 * 1000,
    },
    {
      id: "3d",
      title: "3 days ago",
      subtitle: formatSub(3 * 24 * 60 * 60 * 1000),
      ms: 3 * 24 * 60 * 60 * 1000,
    },
    {
      id: "last_week",
      title: "Last week",
      subtitle: formatSub(7 * 24 * 60 * 60 * 1000),
      ms: 7 * 24 * 60 * 60 * 1000,
    },
    {
      id: "2_weeks",
      title: "2 weeks ago",
      subtitle: formatSub(14 * 24 * 60 * 60 * 1000),
      ms: 14 * 24 * 60 * 60 * 1000,
    },
  ]);

  const handleSubmit = () => {
    isSubmitting = true;
    const opt = options.find((o) => o.id === selectedTimeframe);
    const sinceDate = opt ? new Date(Date.now() - opt.ms).toISOString() : null;

    router.post(
      submitUrl,
      { since: sinceDate },
      {
        preserveState: true,
        onFinish: () => {
          isSubmitting = false;
          open = false;
        },
      },
    );
  };
</script>

<Dialog.Root bind:open>
  <Dialog.Content class="sm:max-w-md">
    <Dialog.Header>
      <Dialog.Title>Recover Failed Messages</Dialog.Title>
      <Dialog.Description class="text-xs text-muted-foreground">
        This operation will cause all failed messages to this {targetName} to be resent.
      </Dialog.Description>
    </Dialog.Header>

    <div class="flex flex-col gap-2 py-3">
      {#each options as opt (opt.id)}
        <button
          type="button"
          class="w-full text-left p-3.5 rounded-lg border transition-all flex flex-col gap-0.5 {selectedTimeframe ===
          opt.id
            ? 'border-foreground/40 bg-accent text-accent-foreground shadow-xs'
            : 'border-border hover:bg-muted/50 text-foreground'}"
          onclick={() => (selectedTimeframe = opt.id)}
        >
          <span class="text-sm font-semibold">{opt.title}</span>
          <span class="text-xs text-muted-foreground">{opt.subtitle}</span>
        </button>
      {/each}
    </div>

    <Dialog.Footer class="flex justify-end gap-2">
      <Button variant="outline" onclick={() => (open = false)} disabled={isSubmitting}>
        Cancel
      </Button>
      <Button onclick={handleSubmit} disabled={isSubmitting}>
        {isSubmitting ? "Recovering..." : "Recover"}
      </Button>
    </Dialog.Footer>
  </Dialog.Content>
</Dialog.Root>
