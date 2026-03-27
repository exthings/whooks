<script lang="ts">
  import type { LinkProps } from "node_modules/@inertiajs/svelte/dist/components/Link.svelte";
  import { cn } from "$lib/utils";
  import { Link } from "@inertiajs/svelte";

  type Props = {
    label: string;
    description: string;
    isActive: boolean;
  } & LinkProps;

  let { isActive, label, description, ...rest }: Props = $props();
</script>

<Link
  class={cn(
    "flex items-center gap-2 px-6 py-4 border-b border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors text-left",
    isActive && "bg-gray-100 border-l-2 border-l-primary",
  )}
  {...rest}
>
  <div class="flex-1">
    <p class={cn("text-sm", isActive && "font-semibold")}>
      {label}
    </p>
    <p class="text-xs text-muted-foreground">
      {description}
    </p>
  </div>
</Link>
