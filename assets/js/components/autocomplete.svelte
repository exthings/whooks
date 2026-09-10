<script lang="ts">
  import { cn } from "$lib/utils.js";
  import { buttonVariants } from "$lib/components/ui/button/index.js";
  import * as Popover from "$lib/components/ui/popover/index.js";
  import * as Command from "$lib/components/ui/command/index.js";
  import { useDebounce } from "runed";
  import {
    ChevronsUpDown,
    Check,
    LoaderCircle,
    X,
  } from "lucide-svelte";

  export type AutocompleteItem = {
    label: string;
    value: string;
    [key: string]: any;
  };

  type Props = {
    id?: string;
    items?: AutocompleteItem[];
    value?: string;
    placeholder?: string;
    searchPlaceholder?: string;
    emptyText?: string;
    loading?: boolean;
    disabled?: boolean;
    clearable?: boolean;
    debounceMs?: number;
    class?: string;
    popoverClass?: string;
    onsearch?: (query: string) => void;
    onchange?: (value: string) => void;
  };

  let {
    id,
    items = [],
    value = $bindable(""),
    placeholder = "Select an option...",
    searchPlaceholder = "Search...",
    emptyText = "No results found.",
    loading = false,
    disabled = false,
    clearable = true,
    debounceMs = 300,
    class: className,
    popoverClass,
    onsearch,
    onchange,
  }: Props = $props();

  let open = $state(false);
  let searchQuery = $state("");
  let selectedLabel = $state("");

  let selectedItem = $derived(items.find((item) => item.value === value));
  let displayLabel = $derived(
    selectedItem?.label || selectedLabel || ""
  );

  const debouncedSearch = useDebounce(
    (query: string) => {
      onsearch?.(query);
    },
    () => debounceMs,
  );

  const handleInput = (e: Event & { currentTarget: HTMLInputElement }) => {
    const query = e.currentTarget.value;
    searchQuery = query;
    if (onsearch) {
      debouncedSearch(query);
    }
  };

  const handleOpenChange = (isOpen: boolean) => {
    open = isOpen;
    if (!isOpen && searchQuery !== "") {
      debouncedSearch.cancel();
      searchQuery = "";
      onsearch?.("");
    }
  };

  const handleSelect = (selectedValue: string) => {
    if (clearable && value === selectedValue) {
      value = "";
      selectedLabel = "";
      onchange?.("");
    } else {
      value = selectedValue;
      const found = items.find((i) => i.value === selectedValue);
      selectedLabel = found?.label || "";
      onchange?.(selectedValue);
    }
    open = false;
  };

  const handleClear = () => {
    value = "";
    selectedLabel = "";
    onchange?.("");
  };
</script>

<Popover.Root bind:open onOpenChange={handleOpenChange}>
  <Popover.Trigger
    {id}
    {disabled}
    class={cn(
      buttonVariants({ variant: "outline" }),
      "w-full justify-between font-normal text-left",
      !displayLabel && "text-muted-foreground",
      className
    )}
  >
    <span class="truncate flex-1">
      {displayLabel || placeholder}
    </span>
    <div class="flex items-center gap-1 shrink-0 ml-2">
      {#if loading}
        <LoaderCircle class="size-4 animate-spin text-muted-foreground" />
      {:else if clearable && value}
        <span
          role="button"
          tabindex="-1"
          class="text-muted-foreground hover:text-foreground rounded p-0.5 cursor-pointer"
          onclick={(e) => {
            e.stopPropagation();
            e.preventDefault();
            handleClear();
          }}
          onkeydown={(e) => {
            if (e.key === "Enter" || e.key === " ") {
              e.stopPropagation();
              e.preventDefault();
              handleClear();
            }
          }}
          aria-label="Clear selection"
        >
          <X class="size-3.5" />
        </span>
      {/if}
      <ChevronsUpDown class="size-4 text-muted-foreground opacity-50" />
    </div>
  </Popover.Trigger>
  <Popover.Content
    class={cn("w-[--bits-popover-anchor-width] min-w-[200px] p-0", popoverClass)}
    align="start"
  >
    <Command.Root shouldFilter={!onsearch}>
      <Command.Input
        placeholder={searchPlaceholder}
        bind:value={searchQuery}
        oninput={handleInput}
      />
      <Command.List>
        {#if loading}
          <div class="flex items-center justify-center p-4 text-sm text-muted-foreground">
            <LoaderCircle class="size-4 animate-spin mr-2" />
            <span>Loading...</span>
          </div>
        {:else}
          <Command.Empty>{emptyText}</Command.Empty>
          <Command.Group>
            {#each items as item (item.value)}
              <Command.Item
                value={item.label}
                keywords={[item.value]}
                onSelect={() => handleSelect(item.value)}
              >
                <Check
                  class={cn(
                    "size-4 shrink-0 mr-2",
                    value === item.value ? "opacity-100" : "opacity-0"
                  )}
                />
                <span class="truncate flex-1">{item.label}</span>
              </Command.Item>
            {/each}
          </Command.Group>
        {/if}
      </Command.List>
    </Command.Root>
  </Popover.Content>
</Popover.Root>
