<script lang="ts">
  import { CopyIcon } from "lucide-svelte";
  import * as Tooltip from "$lib/components/ui/tooltip";

  let { value } = $props();
  let copied = $state(false);

  const copyToClipboard = async () => {
    try {
      console.log("copy");
      const REG_HEX = /&#x([a-fA-F0-9]+);/g;
      const decodedText = value.replace(
        REG_HEX,
        function (_match: any, group1: string) {
          const num = parseInt(group1, 16);
          return String.fromCharCode(num);
        },
      );

      await window.navigator.clipboard.writeText(decodedText);

      copied = true;

      setTimeout(() => (copied = false), 2000);
    } catch (err) {
      console.error("Failed to copy text: ", err);
    }
  };

  const getOpen = () => copied;
  const setOpen = (value: boolean) => (copied = false);
</script>

<button onclick={copyToClipboard} type="button">
  <Tooltip.Root bind:open={getOpen, setOpen} disableHoverableContent>
    <Tooltip.Trigger>
      <CopyIcon size={18} />
    </Tooltip.Trigger>
    <Tooltip.Content>
      <p>Copied!</p>
    </Tooltip.Content>
  </Tooltip.Root>
</button>
