<script lang="ts">
  import * as Empty from "$lib/components/ui/empty";
  import { buttonVariants } from "$lib/components/ui/button";
  import { ShieldOffIcon } from "lucide-svelte";
  import { Link } from "@inertiajs/svelte";
</script>

<svelte:head>
  <title>Whooks - Unauthorized</title>
</svelte:head>

<div class="flex h-[calc(100vh-1rem)] items-center justify-center">
  <Empty.Root>
    <Empty.Header>
      <Empty.Media variant="icon">
        <ShieldOffIcon />
      </Empty.Media>
      <Empty.Title>Unauthorized</Empty.Title>
      <Empty.Description>
        You don't have permission to access this page. Please contact your
        administrator if you think this is an error.
      </Empty.Description>
    </Empty.Header>
    <Empty.Content>
      <div class="flex gap-2">
        <Link
          href="/ui/admin/home"
          class={buttonVariants({ variant: "outline" })}>Back to home</Link
        >
      </div>
    </Empty.Content>
  </Empty.Root>
</div>
