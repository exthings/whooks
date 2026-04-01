<script lang="ts">
  import { router } from "@inertiajs/core";
  import { Label } from "$lib/components/ui/label";
  import { Input } from "$lib/components/ui/input";
  import * as InputGroup from "$lib/components/ui/input-group";
  import Collapsible from "$pages/events/components/collapsible.svelte";
  import StatusFilter from "$pages/events/components/status-filter.svelte";
  import { SearchIcon } from "lucide-svelte";

  const handleIDSearch = (value: string) => {
    if (value)
      router.get(
        "",
        {
          events_params: {
            filters: [
              {
                field: "id",
                op: "eq",
                value: value,
              },
              {
                field: "uid",
                op: "eq",
                value: value,
              },
            ],
          },
        },
        { preserveState: true },
      );
    else
      router.get(
        "",
        { events_params: { filters: [] } },
        { preserveState: true },
      );
  };

  const handleTagsSearch = (value: string) => {
    if (value)
      router.get(
        "",
        {
          events_params: {
            filters: [
              {
                field: "tags",
                op: "contains",
                value: value,
              },
            ],
          },
        },
        { preserveState: true, queryStringArrayFormat: "indices" },
      );
    else
      router.get(
        "",
        { events_params: { filters: [] } },
        { preserveState: true },
      );
  };
</script>

<div class="flex flex-col gap-4">
  <div class="flex flex-col gap-2">
    <Label for="name">ID</Label>
    <InputGroup.Root>
      <InputGroup.Input
        id="id"
        name="id"
        class="text-xs! font-mono"
        placeholder="Search by ID or UID"
        onchange={(e) => handleIDSearch(e.currentTarget.value)}
      />
      <InputGroup.Addon>
        <SearchIcon />
      </InputGroup.Addon>
    </InputGroup.Root>
  </div>

  <Collapsible label="Consumer">
    <Input id="consumer" name="consumer" />
  </Collapsible>

  <Collapsible label="Topic">
    <Input id="topic" name="topic" />
  </Collapsible>

  <Collapsible label="Tags">
    <InputGroup.Root>
      <InputGroup.Input
        id="tags"
        name="tags"
        placeholder="Search by tags"
        class="text-xs!"
        onchange={(e) => handleTagsSearch(e.currentTarget.value)}
      />
      <InputGroup.Addon>
        <SearchIcon />
      </InputGroup.Addon>
    </InputGroup.Root>
  </Collapsible>

  <StatusFilter />
</div>
