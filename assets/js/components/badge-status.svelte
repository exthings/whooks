<script lang="ts" module>
  import { type VariantProps, tv } from "tailwind-variants";
  import { Link } from "@inertiajs/svelte";

  export const badgeVariants = tv({
    base: "focus-visible:border-ring focus-visible:ring-ring/50 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive inline-flex w-fit shrink-0 items-center justify-center gap-1 overflow-hidden whitespace-nowrap rounded-md border px-2 py-0.5 text-xs font-medium transition-[color,box-shadow] focus-visible:ring-[3px] [&>svg]:pointer-events-none [&>svg]:size-3",
    variants: {
      variant: {
        default:
          "bg-primary text-primary-foreground [a&]:hover:bg-primary/90 border-transparent",
        secondary:
          "bg-secondary text-secondary-foreground [a&]:hover:bg-secondary/90 border-transparent",
        destructive:
          "bg-destructive [a&]:hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/70 border-transparent text-white",
        success:
          "bg-green-500 [a&]:hover:bg-green-500/90 focus-visible:ring-green-500/20 dark:focus-visible:ring-green-500/40 dark:bg-green-500/70 border-transparent text-white",
        warning:
          "bg-orange-500 [a&]:hover:bg-orange-500/90 focus-visible:ring-orange-500/20 dark:focus-visible:ring-orange-500/40 dark:bg-orange-500/70 border-transparent text-white",
        info: "bg-blue-500 [a&]:hover:bg-blue-500/90 focus-visible:ring-blue-500/20 dark:focus-visible:ring-blue-500/40 dark:bg-blue-500/70 border-transparent text-white",
        neutral:
          "bg-black [a&]:hover:bg-black/90 focus-visible:ring-black/20 dark:focus-visible:ring-black/40 dark:bg-black/70 border-transparent text-white",
        outline:
          "text-foreground [a&]:hover:bg-accent [a&]:hover:text-accent-foreground",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  });

  export type StatusBadgeVariant = VariantProps<
    typeof badgeVariants
  >["variant"];
</script>

<script lang="ts">
  import { type Icon as IconType } from "lucide-svelte";
  import { type Snippet } from "svelte";
  import { cn } from "$lib/utils.js";

  type Props = {
    variant: StatusBadgeVariant;
    label?: string;
    href?: string;
    icon?: typeof IconType;
    children?: Snippet;
    mono?: boolean;
  };

  let {
    variant = "default",
    label,
    href,
    icon,
    children,
    mono = false,
  }: Props = $props();
</script>

{#if href}
  <Link
    data-slot="badge"
    {href}
    class={cn(badgeVariants({ variant }), mono && "font-mono")}
  >
    {#if icon}
      {@const Icon = icon}
      <Icon />
    {/if}
    {label}
    {@render children?.()}
  </Link>
{:else}
  <span
    data-slot="badge"
    class={cn(badgeVariants({ variant }), mono && "font-mono")}
  >
    {#if icon}
      {@const Icon = icon}
      <Icon />
    {/if}
    {label}
    {@render children?.()}
  </span>
{/if}
