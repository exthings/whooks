<script lang="ts">
  import { Button } from "$lib/components/ui/button";
  import * as InputGroup from "$lib/components/ui/input-group";
  import { PlusIcon, SearchIcon } from "lucide-svelte";

  type Props = {
    title: string;
    onCreate?: () => void;
    onSearch?: (event: Event) => void;
    searchValue?: string;
  };

  let { title, onCreate, onSearch, searchValue }: Props = $props();
</script>

<div class="px-6 py-4 flex flex-col gap-4 border-b">
  <div class="flex items-center justify-between">
    <h1 class="font-bold">{title}</h1>
    {#if onCreate}
      <Button
        variant="outline"
        size="icon"
        class="rounded-full"
        type="button"
        onclick={onCreate}
      >
        <PlusIcon />
      </Button>
    {/if}
  </div>

  <InputGroup.Root>
    <InputGroup.Input
      placeholder="Search..."
      value={searchValue}
      oninput={onSearch}
    />
    <InputGroup.Addon>
      <SearchIcon />
    </InputGroup.Addon>
  </InputGroup.Root>
</div>
