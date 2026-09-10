<script lang="ts">
  import type { User } from "$types";
  import * as Card from "$lib/components/ui/card";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import {
    Activity,
    UserPlus,
    CheckCircle2,
    KeyRound,
    ShieldAlert,
  } from "lucide-svelte";

  type Props = {
    user: User;
  };

  const { user }: Props = $props();

  const events = $derived([
    {
      id: "created",
      title: "Account Created",
      description: `User registered with role "${user.role}"`,
      timestamp: user.insertedAt,
      iconType: "created",
      color:
        "text-blue-500 bg-blue-50 border-blue-200 dark:bg-blue-950 dark:border-blue-800",
    },
    ...(user.confirmedAt
      ? [
          {
            id: "confirmed",
            title: "Account Confirmed",
            description: "Email address verified successfully",
            timestamp: user.confirmedAt,
            iconType: "confirmed",
            color:
              "text-emerald-500 bg-emerald-50 border-emerald-200 dark:bg-emerald-950 dark:border-emerald-800",
          },
        ]
      : []),
    ...(user.authenticatedAt
      ? [
          {
            id: "authenticated",
            title: "Last Authenticated",
            description: "User session authenticated",
            timestamp: user.authenticatedAt,
            iconType: "authenticated",
            color:
              "text-purple-500 bg-purple-50 border-purple-200 dark:bg-purple-950 dark:border-purple-800",
          },
        ]
      : []),
  ]);
</script>

<div class="flex items-center gap-2">
  <Activity class="w-4 h-4" />
  <p class="text-base font-semibold">Activity</p>
</div>

<div>
  <p class="text-xs text-muted-foreground">In road map</p>
</div>
