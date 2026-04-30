<script lang="ts">
  import * as Empty from "$lib/components/ui/empty";
  import { buttonVariants } from "$lib/components/ui/button";
  import { SearchXIcon } from "lucide-svelte";
  import { Link } from "@inertiajs/svelte";
</script>

<svelte:head>
  <title>Whooks - Not Found</title>
</svelte:head>

<div class="flex h-[calc(100vh-1rem)] items-center justify-center">
  <Empty.Root>
    <Empty.Header>
      <Empty.Media variant="icon">
        <SearchXIcon />
      </Empty.Media>
      <Empty.Title>Not Found</Empty.Title>
      <Empty.Description>
        We can't seem to find the page you're looking for. Please check the URL
        or try searching for it.
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
