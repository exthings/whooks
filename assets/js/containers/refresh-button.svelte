<script lang="ts">
  import { Button } from "$lib/components/ui/button";
  import { router } from "@inertiajs/svelte";

  import { RotateCwIcon } from "lucide-svelte";

  type Props = {
    except?: string[];
    only?: string[];
    showProgress?: boolean;
  };

  let { showProgress = true, ...rest }: Props = $props();

  const handleRefresh = () => {
    router.reload({
      queryStringArrayFormat: "indices",
      showProgress,
      ...rest,
    });
  };
</script>

<Button variant="outline" type="button" onclick={handleRefresh}>
  <RotateCwIcon />
</Button>
