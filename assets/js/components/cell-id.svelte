<script lang="ts">
  import { Link } from "@inertiajs/svelte";
  import * as Tooltip from "$lib/components/ui/tooltip";

  type Props = {
    id: string;
    href: string;
    maxVisibleLength?: number;
  };

  let { id, href, maxVisibleLength = 16 }: Props = $props();
</script>

<Tooltip.Provider>
  <Tooltip.Root>
    <Tooltip.Trigger>
      <Link {href} class="hover:underline text-blue-600 font-mono text-[10px]">
        {id.length > maxVisibleLength
          ? id.slice(0, maxVisibleLength) + "..."
          : id}
      </Link>
    </Tooltip.Trigger>
    <Tooltip.Content>
      <p>{id}</p>
    </Tooltip.Content>
  </Tooltip.Root>
</Tooltip.Provider>
