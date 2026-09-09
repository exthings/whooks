<script lang="ts">
  import type { Project } from "$types";
  import BadgeStatus from "$components/badge-status.svelte";
  import type { BadgeStatusVariant } from "$components/badge-status.svelte";
  import { Button } from "$lib/components/ui/button";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import { EllipsisIcon } from "lucide-svelte";

  const STATUS_MAP: Record<Project["status"], BadgeStatusVariant> = {
    enabled: "success",
    disabled: "destructive",
  };

  type Props = {
    project: Project;
  };

  const { project }: Props = $props();
</script>

<header>
  <div class="flex justify-between">
    <div class="flex items-center gap-2 min-h-10">
      <h1 class="text-xl font-semibold">{project.name}</h1>
      <BadgeStatus
        variant={STATUS_MAP[project.status]}
        label={project.status}
      />
    </div>
    <Button variant="outline" size="icon">
      <EllipsisIcon />
    </Button>
  </div>
  <div class="w-full">
    <dl class="text-sm grid grid-cols-4 gap-4">
      <div class="flex flex-col gap-1">
        <dt class="text-xs font-semibold">ID</dt>
        <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
          {project.id}
        </dd>
      </div>
      <div class="flex flex-col gap-1">
        <dt class="text-xs font-semibold">UID</dt>
        <dd class="text-gray-700 sm:col-span-3 font-mono text-xs">
          {project.uid}
        </dd>
      </div>
      <div class="flex flex-col gap-1">
        <dt class="text-xs font-semibold">Inserted at</dt>
        <dd class="text-gray-700 sm:col-span-3">
          <DateTimeDisplay
            value={project.insertedAt}
            size="xs"
            options={{ fractionalSecondDigits: undefined }}
          />
        </dd>
      </div>
      <div class="flex flex-col gap-1">
        <dt class="text-xs font-semibold">Updated at</dt>
        <dd class="text-gray-700 sm:col-span-3">
          <DateTimeDisplay
            value={project.updatedAt}
            size="xs"
            options={{ fractionalSecondDigits: undefined }}
          />
        </dd>
      </div>
    </dl>
  </div>
</header>
