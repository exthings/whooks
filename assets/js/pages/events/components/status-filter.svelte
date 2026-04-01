<script lang="ts">
  import { router } from "@inertiajs/svelte";
  import { Label } from "$lib/components/ui/label";
  import Collapsible from "$pages/events/components/collapsible.svelte";
  import { Checkbox } from "$lib/components/ui/checkbox";

  let selectedStatuses = $state<string[]>([]);
  let count = $derived(selectedStatuses.length);

  const toggleStatus = (status: string) => {
    if (selectedStatuses.includes(status)) {
      selectedStatuses = selectedStatuses.filter((s) => s !== status);
    } else {
      selectedStatuses = [...selectedStatuses, status];
    }
  };

  const clear = () => {
    selectedStatuses = [];
  };

  $effect(() => {
    if (selectedStatuses.length > 0) {
      router.get(
        "",
        {
          events_params: {
            filters: [
              {
                field: "status",
                op: "in",
                value: selectedStatuses,
              },
            ],
          },
        },
        { preserveState: true, queryStringArrayFormat: "brackets" },
      );
    } else {
      router.get(
        "",
        { events_params: { filters: [] } },
        { preserveState: true },
      );
    }
  });
</script>

<Collapsible label="Status" bind:count onClear={clear}>
  <div class="flex flex-col border rounded-md divide-y">
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="pending"
        checked={selectedStatuses.includes("pending")}
        onCheckedChange={() => toggleStatus("pending")}
      />
      <Label for="pending" class="flex-1 text-orange-600">Pending</Label>
    </div>
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="scheduled"
        checked={selectedStatuses.includes("scheduled")}
        onCheckedChange={() => toggleStatus("scheduled")}
      />
      <Label for="scheduled" class="flex-1 text-black">Scheduled</Label>
    </div>
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="processing"
        checked={selectedStatuses.includes("processing")}
        onCheckedChange={() => toggleStatus("processing")}
      />
      <Label for="processing" class="flex-1 text-blue-600">Processing</Label>
    </div>
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="retry"
        checked={selectedStatuses.includes("retry")}
        onCheckedChange={() => toggleStatus("retry")}
      />
      <Label for="retry" class="flex-1 text-gray-600">Retry</Label>
    </div>
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="failed"
        checked={selectedStatuses.includes("failed")}
        onCheckedChange={() => toggleStatus("failed")}
      />
      <Label for="failed" class="flex-1 text-red-600">Failed</Label>
    </div>
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="success"
        checked={selectedStatuses.includes("success")}
        onCheckedChange={() => toggleStatus("success")}
      />
      <Label for="success" class="flex-1 text-green-600">Success</Label>
    </div>
  </div>
</Collapsible>
