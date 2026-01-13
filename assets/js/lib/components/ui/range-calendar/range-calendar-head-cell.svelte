<script lang="ts">
	import { RangeCalendar as RangeCalendarPrimitive } from "bits-ui";
	import { cn } from "$lib/utils.js";

	let {
		ref = $bindable(null),
		class: className,
		...restProps
	}: RangeCalendarPrimitive.HeadCellProps = $props();
</script>

<RangeCalendarPrimitive.HeadCell
	bind:ref
	class={cn(
		"text-muted-foreground flex-1 md:w-(--cell-size) md:flex-none rounded-md text-base md:text-[0.8rem] font-normal",
		className,
	)}
	{...restProps}
/>
