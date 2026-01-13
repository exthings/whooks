<script lang="ts">
  import { buttonVariants } from "$lib/components/ui/button/index.js";
  import { cn } from "$lib/utils.js";
  import { Calendar as CalendarPrimitive } from "bits-ui";

  let {
    ref = $bindable(null),
    class: className,
    ...restProps
  }: CalendarPrimitive.DayProps = $props();
</script>

<CalendarPrimitive.Day
  bind:ref
  class={cn(
    buttonVariants({ variant: "ghost" }),
    "w-full h-full md:size-(--cell-size) flex select-none flex-col items-center justify-center gap-1 whitespace-nowrap py-3 md:p-0 font-normal leading-loose md:leading-none text-xl md:text-sm",
    "[&[data-today]:not([data-selected])]:bg-accent [&[data-today]:not([data-selected])]:text-accent-foreground [&[data-today][data-disabled]]:text-muted-foreground",
    "data-[selected]:bg-primary dark:data-[selected]:hover:bg-accent/50 data-[selected]:text-primary-foreground",
    // Outside months
    "[&[data-outside-month]:not([data-selected])]:text-muted-foreground [&[data-outside-month]:not([data-selected])]:hover:text-accent-foreground",
    // Disabled
    "data-[disabled]:text-muted-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
    // Unavailable
    "data-[unavailable]:text-muted-foreground data-[unavailable]:line-through",
    // hover
    "dark:hover:text-accent-foreground",
    // focus
    "focus:border-ring focus:ring-ring/50 focus:relative",
    // inner spans
    "[&>span]:text-xl [&>span]:opacity-70",
    className,
  )}
  {...restProps}
/>
