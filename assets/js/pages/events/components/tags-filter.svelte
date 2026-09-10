<script lang="ts">
  import Collapsible from "./collapsible.svelte";
  import * as InputGroup from "$lib/components/ui/input-group";
  import { SearchIcon } from "lucide-svelte";

  type Props = {
    value?: string;
    open?: boolean;
    onchange?: (value: string) => void;
  };

  let { value = "", open = true, onchange }: Props = $props();
</script>

<Collapsible label="Tags" {open}>
  <InputGroup.Root>
    <InputGroup.Input
      id="tags"
      name="tags"
      placeholder="Search by tags"
      class="text-xs!"
      {value}
      onchange={(e) => onchange?.(e.currentTarget.value)}
    />
    <InputGroup.Addon>
      <SearchIcon />
    </InputGroup.Addon>
  </InputGroup.Root>
</Collapsible>
