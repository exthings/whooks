<script lang="ts">
  import type { Meta, Event, Topic, Consumer } from "$types";
  import {
    type ColumnDef,
    type VisibilityState,
    getCoreRowModel,
  } from "@tanstack/table-core";
  import { page, router, Deferred } from "@inertiajs/svelte";
  import * as Table from "$lib/components/ui/table";
  import { Button, buttonVariants } from "$lib/components/ui/button";
  import {
    FlexRender,
    createSvelteTable,
    renderComponent,
  } from "$lib/components/ui/data-table";
  import Section from "$components/section.svelte";
  import BadgeStatus from "$components/badge-status.svelte";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import CellId from "$components/cell-id.svelte";
  import CellTags from "$components/cell-tags.svelte";
  import CellText from "$components/cell-text.svelte";
  import LoadingIndicator from "$components/loading-indicatior.svelte";
  import {
    ChevronLeftIcon,
    ChevronRightIcon,
    RotateCwIcon,
  } from "lucide-svelte";
  import { buildHref } from "$utils";

  type Props = {
    propsKey: string;
    columnVisibility?: string[];
  };

  let {
    propsKey,
    columnVisibility = [
      "insertedAt",
      "id",
      "consumer",
      "topic",
      "status",
      "tags",
    ],
  }: Props = $props();

  let events: (Event & { topic: Topic; consumer: Consumer })[] = $derived(
    $page.props[propsKey]?.data,
  );
  let meta: Meta = $derived($page.props[propsKey]?.meta);

  const statusVariantMap = {
    pending: "warning",
    scheduled: "neutral",
    processing: "info",
    retry: "secondary",
    failed: "destructive",
    success: "success",
  } as const;

  const columns: ColumnDef<Event & { topic: Topic }>[] = [
    {
      accessorKey: "insertedAt",
      header: "Inserted At",
      cell: ({ row }) => {
        return renderComponent(DateTimeDisplay, {
          value: row.original.insertedAt,
          size: "xs",
          options: { fractionalSecondDigits: undefined },
          mono: true,
        });
      },
    },
    {
      accessorKey: "id",
      header: "ID",
      cell: ({ row }) => {
        return renderComponent(CellId, {
          id: row.original.id,
          href: buildHref(`/events/${row.original.id}`),
          maxVisibleLength: 64,
        });
      },
    },
    {
      accessorKey: "consumer",
      header: "Consumer",
      cell: ({ row }) => {
        return renderComponent(CellText, {
          text: row.original.consumer.name,
        });
      },
    },
    {
      accessorKey: "topic",
      header: "Topic",
      cell: ({ row }) => {
        return renderComponent(CellText, {
          text: row.original.topic.name,
        });
      },
    },
    {
      accessorKey: "status",
      header: "Status",
      cell: ({ row }) => {
        return renderComponent(BadgeStatus, {
          variant: statusVariantMap[row.original.status],
          label: row.original.status,
        });
      },
    },
    {
      accessorKey: "tags",
      header: "Tags",
      cell: ({ row }) => {
        return renderComponent(CellTags, {
          tags: row.original.tags,
        });
      },
    },
  ];

  let tableColumnVisibility = $derived(
    columns.reduce((acc, col) => {
      const key = (col as any).accessorKey;
      if (key) {
        acc[key] = columnVisibility.includes(key);
      }
      return acc;
    }, {} as VisibilityState),
  );

  const table = createSvelteTable({
    get data() {
      return events;
    },
    columns,
    getCoreRowModel: getCoreRowModel(),
    state: {
      get columnVisibility() {
        return tableColumnVisibility;
      },
    },
  });

  const handleRefresh = () => {
    router.get(
      "",
      {
        events_params: {},
      },
      {
        queryStringArrayFormat: "indices",
        preserveState: true,
        only: ["events"],
      },
    );
  };

  const handlePageChange = (page: number | null) => {
    if (!page) {
      return;
    }

    router.get(
      "",
      {
        events_params: {
          filters: meta.filters,
          page,
        },
      },
      {
        preserveState: true,
        preserveScroll: true,
        only: [propsKey],
      },
    );
  };
</script>

{#snippet eventsActions()}
  <div>
    <Button size="sm" variant="outline" type="button" onclick={handleRefresh}>
      <RotateCwIcon />
      Refresh
    </Button>
  </div>
{/snippet}

<Section title="Latest events" actions={eventsActions}>
  <div class="w-full">
    <div class="rounded-md border">
      <Table.Root>
        <Table.Header>
          {#each table.getHeaderGroups() as headerGroup (headerGroup.id)}
            <Table.Row>
              {#each headerGroup.headers as header (header.id)}
                <Table.Head class="[&:has([role=checkbox])]:ps-3">
                  {#if !header.isPlaceholder}
                    <FlexRender
                      content={header.column.columnDef.header}
                      context={header.getContext()}
                    />
                  {/if}
                </Table.Head>
              {/each}
            </Table.Row>
          {/each}
        </Table.Header>
        <Deferred data={propsKey}>
          {#snippet fallback()}
            <Table.Body>
              <Table.Row>
                <Table.Cell colspan={columns.length}>
                  <LoadingIndicator />
                </Table.Cell>
              </Table.Row>
            </Table.Body>
          {/snippet}
          <Table.Body>
            {#each table.getRowModel().rows as row (row.id)}
              <Table.Row data-state={row.getIsSelected() && "selected"}>
                {#each row.getVisibleCells() as cell (cell.id)}
                  <Table.Cell class="[&:has([role=checkbox])]:ps-3">
                    <FlexRender
                      content={cell.column.columnDef.cell}
                      context={cell.getContext()}
                    />
                  </Table.Cell>
                {/each}
              </Table.Row>
            {:else}
              <Table.Row>
                <Table.Cell colspan={columns.length} class="h-24 text-center">
                  No results.
                </Table.Cell>
              </Table.Row>
            {/each}
          </Table.Body>
        </Deferred>
      </Table.Root>
    </div>
    {#if meta}
      <div class="flex items-center justify-end space-x-2 pt-3">
        <div class="text-muted-foreground flex-1 text-xs">
          {meta.total_count} events
        </div>
        <div class="flex items-center space-x-2">
          <Button
            variant="ghost"
            size="sm"
            type="button"
            disabled={!meta?.has_previous_page}
            onclick={() => handlePageChange(meta.previous_page)}
          >
            <ChevronLeftIcon />
          </Button>
          <div class={buttonVariants({ variant: "outline", size: "sm" })}>
            {meta.current_page}
          </div>
          <Button
            variant="ghost"
            size="sm"
            type="button"
            disabled={!meta?.has_next_page}
            onclick={() => handlePageChange(meta.next_page)}
          >
            <ChevronRightIcon />
          </Button>
        </div>
      </div>
    {/if}
  </div>
</Section>
