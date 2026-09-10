<script lang="ts">
  import { Label } from "$lib/components/ui/label";
  import Collapsible from "./collapsible.svelte";
  import { Checkbox } from "$lib/components/ui/checkbox";

  type Props = {
    selected?: string[];
    open?: boolean;
    onchange?: (statuses: string[]) => void;
    onclear?: () => void;
  };

  let {
    selected = [],
    open = true,
    onchange,
    onclear,
  }: Props = $props();

  let count = $derived(selected.length);

  const toggleStatus = (status: string) => {
    const next = selected.includes(status)
      ? selected.filter((s) => s !== status)
      : [...selected, status];

    onchange?.(next);
  };

  const clear = () => {
    onclear?.();
  };
</script>

<Collapsible label="Status" {count} onClear={clear} {open}>
  <div class="flex flex-col border rounded-md divide-y">
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="pending"
        checked={selected.includes("pending")}
        onCheckedChange={() => toggleStatus("pending")}
      />
      <Label for="pending" class="flex-1 text-orange-600">Pending</Label>
    </div>
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="scheduled"
        checked={selected.includes("scheduled")}
        onCheckedChange={() => toggleStatus("scheduled")}
      />
      <Label for="scheduled" class="flex-1 text-black">Scheduled</Label>
    </div>
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="processing"
        checked={selected.includes("processing")}
        onCheckedChange={() => toggleStatus("processing")}
      />
      <Label for="processing" class="flex-1 text-blue-600">Processing</Label>
    </div>
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="retry"
        checked={selected.includes("retry")}
        onCheckedChange={() => toggleStatus("retry")}
      />
      <Label for="retry" class="flex-1 text-gray-600">Retry</Label>
    </div>
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="failed"
        checked={selected.includes("failed")}
        onCheckedChange={() => toggleStatus("failed")}
      />
      <Label for="failed" class="flex-1 text-red-600">Failed</Label>
    </div>
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="success"
        checked={selected.includes("success")}
        onCheckedChange={() => toggleStatus("success")}
      />
      <Label for="success" class="flex-1 text-green-600">Success</Label>
    </div>
    <div class="flex items-center gap-3 py-2 px-2">
      <Checkbox
        id="no_subscribers"
        checked={selected.includes("no_subscribers")}
        onCheckedChange={() => toggleStatus("no_subscribers")}
      />
      <Label for="no_subscribers" class="flex-1 text-slate-500">No Subscribers</Label>
    </div>
  </div>
</Collapsible>
