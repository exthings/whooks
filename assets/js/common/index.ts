import type { BadgeStatusVariant } from "$components/badge-status.svelte";


export const getSuccessRateLabel = (rate: number): { label: string, variant: BadgeStatusVariant } => {
  if (rate >= 95) {
    return { label: "Excellent", variant: "success" };
  }

  if (rate >= 80) {
    return { label: "Good", variant: "info" };
  }

  if (rate >= 60) {
    return { label: "Degraded", variant: "warning" };
  }

  return { label: "Poor", variant: "destructive" };
}