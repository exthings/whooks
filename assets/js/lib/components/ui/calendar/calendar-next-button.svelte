<script lang="ts">
  import { Calendar as CalendarPrimitive } from "bits-ui";
  import ChevronRightIcon from "@lucide/svelte/icons/chevron-right";
  import {
    buttonVariants,
    type ButtonVariant,
  } from "$lib/components/ui/button/index.js";
  import { cn } from "$lib/utils.js";

  let {
    ref = $bindable(null),
    class: className,
    children,
    variant = "ghost",
    ...restProps
  }: CalendarPrimitive.NextButtonProps & {
    variant?: ButtonVariant;
  } = $props();
</script>

{#snippet Fallback()}
  <ChevronRightIcon class="size-6 md:size-4" />
{/snippet}

<CalendarPrimitive.NextButton
  bind:ref
  class={cn(
    buttonVariants({ variant }),
    "min-w-10 min-h-10 md:size-(--cell-size) select-none bg-transparent p-2 disabled:opacity-50 rtl:rotate-180 flex-shrink-0",
    className,
  )}
  children={children || Fallback}
  {...restProps}
/>
