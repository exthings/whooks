<script lang="ts">
  import type { Endpoint } from "$types/endpoint";
  import { type ColumnDef, getCoreRowModel } from "@tanstack/table-core";
  import * as Table from "$lib/components/ui/table";
  import { Button } from "$lib/components/ui/button";
  import {
    FlexRender,
    createSvelteTable,
    renderComponent,
  } from "$lib/components/ui/data-table";
  import CellLabelDescription from "$components/cell-label-description.svelte";
  import BadgeStatus from "$components/badge-status.svelte";
  import DateTimeDisplay from "$components/date-time-display.svelte";

  let { endpoints }: { endpoints: Endpoint[] } = $props();

  const columns: ColumnDef<Endpoint>[] = [
    {
      accessorKey: "url",
      header: "URL",
      cell: ({ row }) => {
        return renderComponent(CellLabelDescription, {
          label: row.original.url,
          description: row.original.description,
        });
      },
    },
    {
      accessorKey: "status",
      header: "Status",
      cell: ({ row }) => {
        return renderComponent(BadgeStatus, {
          variant:
            row.original.status === "enabled" ? "success" : "destructive",
          label: row.original.status,
        });
      },
    },
    {
      accessorKey: "updatedAt",
      header: "Updated At",
      cell: ({ row }) => {
        return renderComponent(DateTimeDisplay, {
          value: row.original.updatedAt,
          size: "sm",
          options: { fractionalSecondDigits: undefined },
        });
      },
    },
  ];

  const table = createSvelteTable({
    get data() {
      return endpoints;
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
