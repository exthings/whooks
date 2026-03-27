<script lang="ts">
  import { Badge } from "$lib/components/ui/badge/index.js";
  import { cn } from "$lib/utils.js";
  import * as Accordion from "$lib/components/ui/accordion/index.js";
  import * as Card from "$lib/components/ui/card/index.js";

  let { schema }: { schema: any } = $props();

  const typeColors: Record<string, string> = {
    string:
      "text-green-600 dark:text-green-400 bg-green-100 dark:bg-green-900/30",
    number: "text-blue-600 dark:text-blue-400 bg-blue-100 dark:bg-blue-900/30",
    integer: "text-blue-600 dark:text-blue-400 bg-blue-100 dark:bg-blue-900/30",
    boolean:
      "text-orange-600 dark:text-orange-400 bg-orange-100 dark:bg-orange-900/30",
    object:
      "text-purple-600 dark:text-purple-400 bg-purple-100 dark:bg-purple-900/30",
    array:
      "text-yellow-600 dark:text-yellow-400 bg-yellow-100 dark:bg-yellow-900/30",
    null: "text-gray-600 dark:text-gray-400 bg-gray-100 dark:bg-gray-900/30",
  };

  const getTypeColor = (type: string) => {
    return typeColors[type] || "text-muted-foreground bg-muted";
  };
</script>

{#snippet propertyRow(
  name: string,
  propSchema: any,
  isRequired: boolean,
  isLast: boolean = false,
)}
  <div class={cn("flex flex-col py-3", !isLast && "border-b border-border/50")}>
    <div class="flex items-start justify-between gap-4">
      <div class="flex items-center gap-2">
        <span class="font-mono text-sm font-semibold">
          {name}
          {#if isRequired}
            <span class="text-red-600"> * </span>
          {/if}
        </span>

        <span
          class={cn(
            "px-2 py-0.5 rounded-md text-xs font-medium font-mono",
            getTypeColor(propSchema.type),
          )}
        >
          {propSchema.type || "any"}
        </span>
      </div>
      {#if propSchema.description}
        <span class="text-xs text-muted-foreground"
          >{propSchema.description}</span
        >
      {/if}
    </div>

    {#if propSchema.type === "object" && propSchema.properties}
      <div class="pl-4 mt-3 ml-2 border-l-2 border-muted">
        {@render objectProperties(propSchema)}
      </div>
    {:else if propSchema.type === "array" && propSchema.items}
      <div class="pl-4 mt-3 ml-2 border-l-2 border-muted">
        <span
          class="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2 block"
          >Items</span
        >
        {#if propSchema.items.type === "object"}
          <div class="bg-muted/30 rounded-md p-3 border border-border/50">
            {@render objectProperties(propSchema.items)}
          </div>
        {:else}
          <div class="flex items-center gap-2 py-1">
            <span
              class={cn(
                "px-2 py-0.5 rounded-md text-xs font-medium font-mono",
                getTypeColor(propSchema.items.type),
              )}
            >
              {propSchema.items.type}
            </span>
            {#if propSchema.items.description}
              <span class="text-sm text-muted-foreground"
                >{propSchema.items.description}</span
              >
            {/if}
          </div>
        {/if}
      </div>
    {/if}
  </div>
{/snippet}

{#snippet objectProperties(objSchema: any)}
  {#if objSchema.properties}
    {@const entries = Object.entries(objSchema.properties)}
    <div class="flex flex-col w-full">
      {#each entries as [name, val], index (name)}
        {@const isLast = index === entries.length - 1}
        {@const isRequired = objSchema.required?.includes(name) || false}
        {@render propertyRow(name, val, isRequired, isLast)}
      {/each}
    </div>
  {:else}
    <div class="text-sm text-muted-foreground py-2 italic">
      No properties defined
    </div>
  {/if}
{/snippet}

<div class="">
  {#if schema.type === "object" || !schema.type}
    {@render objectProperties(schema)}
  {:else}
    <div class="flex items-center gap-2">
      <span class="text-muted-foreground">Root element type:</span>
      <span
        class={cn(
          "px-2 py-0.5 rounded-md text-xs font-medium font-mono",
          getTypeColor(schema.type),
        )}
      >
        {schema.type}
      </span>
    </div>
  {/if}
</div>
