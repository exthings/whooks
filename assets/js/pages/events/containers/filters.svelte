<script lang="ts">
  import { router, page } from "@inertiajs/svelte";
  import type { Last as LastType } from "$types";
  import { getFilterValue } from "$utils";
  import { Button } from "$lib/components/ui/button";
  import Collapsible from "../components/collapsible.svelte";
  import Last from "../components/last.svelte";
  import IdFilter from "../components/id-filter.svelte";
  import TagsFilter from "../components/tags-filter.svelte";
  import StatusFilter from "../components/status-filter.svelte";
  import ProjectFilter from "../components/project-filter.svelte";
  import ConsumerFilter from "../components/consumer-filter.svelte";

  let meta = $derived($page.props?.["events"]?.["meta"]);

  let lastValue = $derived.by<LastType | string>(() => {
    return ($page.props?.["globalFilters"]?.["last"] as LastType) || "";
  });

  let idValue = $derived.by<string>(() => {
    if (meta?.filters) {
      let filter = getFilterValue(meta.filters, ["id", "uid"])[0];
      if (filter) return filter.value;
    }
    return "";
  });

  let tagValue = $derived.by<string>(() => {
    if (meta?.filters) {
      let filter = getFilterValue(meta.filters, "tags")[0];
      if (filter) return filter.value;
    }
    return "";
  });

  let projectIdValue = $derived.by<string>(() => {
    if (meta?.filters) {
      let filter = getFilterValue(meta.filters, "project_id")[0];
      if (filter) return filter.value;
    }
    return "";
  });

  let consumerIdValue = $derived.by<string>(() => {
    if (meta?.filters) {
      let filter = getFilterValue(meta.filters, "consumer_id")[0];
      if (filter) return filter.value;
    }
    return "";
  });

  let selectedStatuses = $derived.by<string[]>(() => {
    if (meta?.filters) {
      let filter = getFilterValue(meta.filters, "status")[0];
      if (filter) {
        if (Array.isArray(filter.value)) return filter.value;
        if (typeof filter.value === "string") return [filter.value];
      }
    }
    return [];
  });

  let projectsData = $derived(
    ($page.props?.["projects"]?.["data"] as any[]) || [],
  );
  let consumersData = $derived(
    ($page.props?.["consumers"]?.["data"] as any[]) || [],
  );

  let projectItems = $derived(
    projectsData.map((p: any) => ({
      label: p.name || p.uid || p.id,
      value: p.id,
    })),
  );

  let consumerItems = $derived(
    consumersData.map((c: any) => ({
      label: c.name || c.uid || c.id,
      value: c.id,
    })),
  );

  let projectsLoading = $state(false);
  let consumersLoading = $state(false);

  let hasActiveFilters = $derived(
    Boolean(
      idValue ||
        tagValue ||
        selectedStatuses.length > 0 ||
        projectIdValue ||
        consumerIdValue ||
        (lastValue && lastValue !== "1h"),
    ),
  );

  const handleSearch = (
    data: Record<string, any>,
    options: Record<string, any> = {},
  ) => {
    router.reload({
      data,
      showProgress: true,
      ...options,
    });
  };

  const buildCurrentFilters = (
    overrides: {
      id?: string;
      tag?: string;
      statuses?: string[];
      projectId?: string;
      consumerId?: string;
    } = {},
  ) => {
    const currentId = overrides.id !== undefined ? overrides.id : idValue;
    const currentTag = overrides.tag !== undefined ? overrides.tag : tagValue;
    const currentStatuses =
      overrides.statuses !== undefined ? overrides.statuses : selectedStatuses;
    const currentProjectId =
      overrides.projectId !== undefined ? overrides.projectId : projectIdValue;
    const currentConsumerId =
      overrides.consumerId !== undefined
        ? overrides.consumerId
        : consumerIdValue;

    const filters: Array<{ field: string; op: string; value: any }> = [];

    if (currentId) {
      filters.push({
        field: currentId.startsWith("event_") ? "id" : "uid",
        op: "==",
        value: currentId,
      });
    }

    if (currentTag) {
      filters.push({
        field: "tags",
        op: "contains",
        value: currentTag,
      });
    }

    if (currentStatuses.length > 0) {
      filters.push({
        field: "status",
        op: "in",
        value: currentStatuses,
      });
    }

    if (currentProjectId) {
      filters.push({
        field: "project_id",
        op: "==",
        value: currentProjectId,
      });
    }

    if (currentConsumerId) {
      filters.push({
        field: "consumer_id",
        op: "==",
        value: currentConsumerId,
      });
    }

    return filters;
  };

  const handleLastChange = (value: string) => {
    const filters = buildCurrentFilters();

    handleSearch(
      {
        last: value,
        events_params: { filters },
      },
      { queryStringArrayFormat: "indices" },
    );
  };

  const handleIDChange = (value: string) => {
    const filters = buildCurrentFilters({ id: value });

    handleSearch({
      last: "",
      events_params: { filters },
    });
  };

  const handleTagsChange = (value: string) => {
    const filters = buildCurrentFilters({ tag: value });

    handleSearch(
      {
        last: "",
        events_params: { filters },
      },
      { queryStringArrayFormat: "indices" },
    );
  };

  const handleProjectChange = (value: string) => {
    const filters = buildCurrentFilters({ projectId: value });

    handleSearch(
      {
        last: lastValue || "1h",
        events_params: { filters },
      },
      { queryStringArrayFormat: "indices" },
    );
  };

  const handleConsumerChange = (value: string) => {
    const filters = buildCurrentFilters({ consumerId: value });

    handleSearch(
      {
        last: lastValue || "1h",
        events_params: { filters },
      },
      { queryStringArrayFormat: "indices" },
    );
  };

  const handleProjectSearch = (query: string) => {
    projectsLoading = true;
    router.reload({
      only: ["projects"],
      data: {
        projects_params: {
          filters: query
            ? [
                {
                  field: "name",
                  op: "ilike",
                  value: query,
                },
              ]
            : [],
        },
      },
      queryStringArrayFormat: "indices",
      onFinish: () => {
        projectsLoading = false;
      },
    });
  };

  const handleConsumerSearch = (query: string) => {
    consumersLoading = true;
    router.reload({
      only: ["consumers"],
      data: {
        consumers_params: {
          filters: query
            ? [
                {
                  field: "name",
                  op: "ilike",
                  value: query,
                },
              ]
            : [],
        },
      },
      queryStringArrayFormat: "indices",
      onFinish: () => {
        consumersLoading = false;
      },
    });
  };

  const handleStatusChange = (statuses: string[]) => {
    const filters = buildCurrentFilters({ statuses });

    handleSearch(
      {
        last: lastValue || "1h",
        events_params: { filters },
      },
      { queryStringArrayFormat: "indices" },
    );
  };

  const handleStatusClear = () => {
    const filters = buildCurrentFilters({ statuses: [] });

    handleSearch(
      {
        last: lastValue || "1h",
        events_params: { filters },
      },
      { queryStringArrayFormat: "indices" },
    );
  };

  const handleClearAll = () => {
    handleSearch(
      {
        last: "1h",
        events_params: { filters: [] },
      },
      { queryStringArrayFormat: "indices" },
    );
  };
</script>

<div class="flex flex-col gap-4">
  <IdFilter value={idValue} onchange={handleIDChange} />

  <TagsFilter value={tagValue} onchange={handleTagsChange} />

  <ProjectFilter
    value={projectIdValue}
    items={projectItems}
    loading={projectsLoading}
    onsearch={handleProjectSearch}
    onchange={handleProjectChange}
  />

  <ConsumerFilter
    value={consumerIdValue}
    items={consumerItems}
    loading={consumersLoading}
    onsearch={handleConsumerSearch}
    onchange={handleConsumerChange}
  />

  <Collapsible label="Time range" open>
    <Last
      value={lastValue}
      disabled={Boolean(idValue || tagValue)}
      onValueChange={handleLastChange}
    />
  </Collapsible>

  <StatusFilter
    selected={selectedStatuses}
    onchange={handleStatusChange}
    onclear={handleStatusClear}
  />

  <Button
    variant="outline"
    size="sm"
    class="w-full"
    onclick={handleClearAll}
    disabled={!hasActiveFilters}
  >
    Clear
  </Button>
</div>
