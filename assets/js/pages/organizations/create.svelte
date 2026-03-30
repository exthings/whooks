<script lang="ts">
  import * as Empty from "$lib/components/ui/empty/index.js";

  import { Button } from "$lib/components/ui/button/index.js";
  import { Building2Icon } from "lucide-svelte";
</script>

<Empty.Root class="h-[calc(100vh-1rem)]">
  <Empty.Header>
    <Empty.Media variant="icon">
      <Building2Icon />
    </Empty.Media>
    <Empty.Title class="text-2xl">No organization yet</Empty.Title>
    <Empty.Description class="text-md">
      You haven't created any organization yet.
      <br />
      Get started by creating your first organization.
    </Empty.Description>
  </Empty.Header>
  <Empty.Content>
    <div class="flex gap-2">
      <Button>Create organization</Button>
    </div>
  </Empty.Content>
</Empty.Root>
