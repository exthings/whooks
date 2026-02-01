<script lang="ts">
  import type { Event, Topic } from "$types";
  import { type ColumnDef, getCoreRowModel } from "@tanstack/table-core";
  import * as Table from "$lib/components/ui/table";
  import { Button } from "$lib/components/ui/button";
  import {
    FlexRender,
    createSvelteTable,
    renderComponent,
  } from "$lib/components/ui/data-table";
  import BadgeStatus from "$components/badge-status.svelte";
  import DateTimeDisplay from "$components/date-time-display.svelte";
  import CellId from "$components/cell-id.svelte";
  import CellTags from "$components/cell-tags.svelte";
  import CellText from "$components/cell-text.svelte";

  let { events }: { events: (Event & { topic: Topic })[] } = $props();

  const statusVariantMap = {
    pending: "warning",
    scheduled: "success",
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
          href: `/ui/admin/events/${row.original.id}`,
          maxVisibleLength: 64,
        });
      },
    },
    {
      accessorKey: "topic.name",
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

  const table = createSvelteTable({
    get data() {
      return events;
    },
    columns,
    getCoreRowModel: getCoreRowModel(),
  });
</script>

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
    </Table.Root>
  </div>
  <div class="flex items-center justify-end space-x-2 pt-3">
    <div class="text-muted-foreground flex-1 text-sm">
      {table.getFilteredSelectedRowModel().rows.length} of
      {table.getFilteredRowModel().rows.length} row(s) selected.
    </div>
    <div class="space-x-2">
      <Button
        variant="outline"
        size="sm"
        onclick={() => table.previousPage()}
        disabled={!table.getCanPreviousPage()}
      >
        Previous
      </Button>
      <Button
        variant="outline"
        size="sm"
        onclick={() => table.nextPage()}
        disabled={!table.getCanNextPage()}
      >
        Next
      </Button>
    </div>
  </div>
</div>
