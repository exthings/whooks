<script lang="ts">
  let { label, description }: { label: string; description: string } = $props();
</script>

<div>
  <p>{label}</p>
  <p class="text-xs text-gray-500">{description}</p>
</div>
