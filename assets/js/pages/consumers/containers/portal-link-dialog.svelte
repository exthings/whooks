<script lang="ts">
  import * as Dialog from "$lib/components/ui/dialog/index.js";
  import CopyClipboard from "$components/copy-clipboard.svelte";

  type Props = {
    open: boolean;
    portalLink?: string;
  };

  let { open = $bindable(), portalLink }: Props = $props();
</script>

<Dialog.Root bind:open>
  <Dialog.Content class="sm:max-w-4xl">
    <Dialog.Header>
      <Dialog.Title>Portal link</Dialog.Title>
      <Dialog.Description>
        <div class="flex items-center gap-2">
          <span class="font-mono text-sm">
            {portalLink}
          </span>
          <CopyClipboard value={portalLink} />
        </div>
      </Dialog.Description>
    </Dialog.Header>
  </Dialog.Content>
</Dialog.Root>
