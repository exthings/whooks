<script lang="ts">
  import { Label } from "$lib/components/ui/label";
  import * as InputGroup from "$lib/components/ui/input-group";
  import { SearchIcon } from "lucide-svelte";

  type Props = {
    value?: string;
    onchange?: (value: string) => void;
  };

  let { value = "", onchange }: Props = $props();
</script>

<div class="flex flex-col gap-2">
  <Label for="id">ID</Label>
  <InputGroup.Root>
    <InputGroup.Input
      id="id"
      name="id"
      class="text-xs! font-mono"
      placeholder="Search by ID or UID"
      {value}
      onchange={(e) => onchange?.(e.currentTarget.value)}
    />
    <InputGroup.Addon>
      <SearchIcon />
    </InputGroup.Addon>
  </InputGroup.Root>
</div>
