<script lang="ts">
  type Props = {
    data: any;
    theme?: string;
    showCopy?: boolean;
    expanded?: number | boolean;
    indent?: number;
  };

  const {
    data,
    showCopy = true,
    expanded = 1,
    indent = 2,
    theme = "material-lighter",
  }: Props = $props();
</script>

<div class="font-mono text-xs overflow-auto rounded-lg">
  <andypf-json-viewer {data} {theme} {expanded} {indent} {showCopy}>
  </andypf-json-viewer>
</div>
