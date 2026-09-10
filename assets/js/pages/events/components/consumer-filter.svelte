<script lang="ts">
  import Collapsible from "./collapsible.svelte";
  import Autocomplete, {
    type AutocompleteItem,
  } from "$components/autocomplete.svelte";

  type Props = {
    value?: string;
    items?: AutocompleteItem[];
    loading?: boolean;
    open?: boolean;
    onsearch?: (query: string) => void;
    onchange?: (value: string) => void;
    onclear?: () => void;
  };

  let {
    value = "",
    items = [],
    loading = false,
    open = true,
    onsearch,
    onchange,
    onclear,
  }: Props = $props();

  let count = $derived(value ? 1 : undefined);

  const handleClear = () => {
    onchange?.("");
    onclear?.();
  };
</script>

<Collapsible label="Consumer" {open}>
  <Autocomplete
    id="consumer-filter"
    placeholder="Select consumer..."
    searchPlaceholder="Search consumers..."
    emptyText="No consumers found."
    {value}
    {items}
    {loading}
    {onsearch}
    {onchange}
  />
</Collapsible>
