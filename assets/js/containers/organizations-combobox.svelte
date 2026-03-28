<script lang="ts">
  import { page, Deferred } from "@inertiajs/svelte";
  import { Button } from "$lib/components/ui/button";
  import { buttonVariants } from "$lib/components/ui/button/index.js";
  import { Input } from "$lib/components/ui/input/index.js";
  import { ScrollArea } from "$lib/components/ui/scroll-area/index.js";
  import LoadingIndicator from "$components/loading-indicatior.svelte";
  import { cn } from "$lib/utils.js";
  import { PersistedState } from "runed";
  import OrganizationForm from "$containers/organization-form.svelte";

  import * as Popover from "$lib/components/ui/popover/index.js";

  import {
    Building2,
    PlusIcon,
    ChevronsUpDownIcon,
    CheckIcon,
  } from "lucide-svelte";

  type Props = {
    organization: PersistedState<string | null>;
    setOrganization: (org: string) => void;
  };

  let { organization, setOrganization }: Props = $props();

  let open = $state(false);
  let organizations = $derived($page.props["organizations"]);
  let organizationForm = $state(false);

  const handleSetOrganization = (org: string) => {
    setOrganization(org);
    open = false;
  };
</script>

<Popover.Root bind:open>
  <Popover.Trigger
    class={cn(buttonVariants({ variant: "outline" }), "w-full justify-between")}
  >
    <span class="flex items-center gap-2">
      <Building2 />
      {#if organization.current}
        {organizations?.data.find((org) => org.id === organization.current)
          ?.name}
      {:else}
        Select organization
      {/if}
    </span>
    <ChevronsUpDownIcon />
  </Popover.Trigger>
  <Popover.Content class="p-2 flex flex-col gap-2" align="start">
    <div>
      <Input
        name="search"
        placeholder="Search organization"
        class="focus-visible:ring-0"
      />
    </div>

    <ScrollArea class="h-40">
      <ul class="flex flex-col">
        <Deferred data="organizations">
          {#snippet fallback()}
            <LoadingIndicator />
          {/snippet}
          {#each organizations.data as org}
            <li class="text-left">
              <Button
                variant="ghost"
                size="sm"
                class="w-full justify-start font-normal"
                type="button"
                onclick={() => handleSetOrganization(org.id)}
              >
                {#if organization.current === org.id}
                  <CheckIcon />
                {:else}
                  <span class="size-3.5"></span>
                {/if}
                {org.name}
              </Button>
            </li>
          {/each}
        </Deferred>
      </ul>
    </ScrollArea>
    <div>
      <Button
        variant="outline"
        size="sm"
        class="w-full"
        onclick={() => (organizationForm = true)}
      >
        <PlusIcon />
        Create
      </Button>
    </div>
  </Popover.Content>
</Popover.Root>

<OrganizationForm bind:open={organizationForm} />
