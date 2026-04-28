<script lang="ts">
  import { router } from "@inertiajs/svelte";
  import * as Avatar from "$lib/components/ui/avatar/index.js";
  import * as DropdownMenu from "$lib/components/ui/dropdown-menu/index.js";
  import * as Sidebar from "$lib/components/ui/sidebar/index.js";
  import { useSidebar } from "$lib/components/ui/sidebar/index.js";
  import { LogOutIcon, EllipsisVertical, User } from "@lucide/svelte";

  type Props = {
    name: string;
    email: string;
    avatar?: string;
  };

  let { name, email, avatar }: Props = $props();
  const sidebar = useSidebar();

  const handleLogOut = (e: Event) => {
    e.preventDefault();
    router.delete("/ui/auth/logout");
  };
</script>

<Sidebar.Menu>
  <Sidebar.MenuItem>
    <DropdownMenu.Root>
      <DropdownMenu.Trigger>
        {#snippet child({ props })}
          <Sidebar.MenuButton
            size="lg"
            class="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
            {...props}
          >
            <Avatar.Root class="size-8 rounded-lg">
              <Avatar.Image src={avatar} alt={name} />
              <Avatar.Fallback
                class="rounded-lg bg-neutral-200 text-neutral-500"
                ><User /></Avatar.Fallback
              >
            </Avatar.Root>
            <div class="grid flex-1 text-left text-sm leading-tight">
              <span class="truncate font-medium">{name}</span>
              <span class="truncate text-xs">{email}</span>
            </div>
            <EllipsisVertical class="ml-auto size-4" />
          </Sidebar.MenuButton>
        {/snippet}
      </DropdownMenu.Trigger>
      <DropdownMenu.Content
        class="w-(--bits-dropdown-menu-anchor-width) min-w-56 rounded-lg"
        side={sidebar.isMobile ? "bottom" : "right"}
        align="end"
        sideOffset={4}
      >
        <DropdownMenu.Label class="p-0 font-normal">
          <div class="flex items-center gap-2 px-1 py-1.5 text-left text-sm">
            <Avatar.Root class="size-8 rounded-lg">
              <Avatar.Image src={avatar} alt={name} />
              <Avatar.Fallback
                class="rounded-lg bg-neutral-200 text-neutral-500"
                ><User /></Avatar.Fallback
              >
            </Avatar.Root>
            <div class="grid flex-1 text-left text-sm leading-tight">
              <span class="truncate font-medium">{name}</span>
              <span class="truncate text-xs">{email}</span>
            </div>
          </div>
        </DropdownMenu.Label>

        <DropdownMenu.Separator />
        <DropdownMenu.Item onclick={handleLogOut}>
          <LogOutIcon />
          Logout
        </DropdownMenu.Item>
      </DropdownMenu.Content>
    </DropdownMenu.Root>
  </Sidebar.MenuItem>
</Sidebar.Menu>
