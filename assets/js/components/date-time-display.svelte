<script lang="ts">
  import { parseAbsoluteToLocal } from "@internationalized/date";

  type Props = {
    value: string;
    locale?: string;
    options?: Intl.DateTimeFormatOptions;
    size?: "xs" | "sm" | "base" | "lg" | "xl";
    mono?: boolean;
  };

  const defaultOptions: Intl.DateTimeFormatOptions = {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    fractionalSecondDigits: 3,
  };

  let {
    value,
    locale = navigator.language,
    options = {},
    size = "xs",
    mono = false,
  }: Props = $props();

  let parsedDate = $derived(parseAbsoluteToLocal(value));

  let formatter = new Intl.DateTimeFormat(
    locale,
    Object.assign(defaultOptions, options),
  );
</script>

<time datetime={value} class="text-{size} {mono ? 'font-mono' : ''}">
  {formatter.format(parsedDate.toDate())}
</time>
