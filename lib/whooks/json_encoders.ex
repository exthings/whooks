defimpl Jason.Encoder, for: Flop.Meta do
  def encode(value, opts) do
    Jason.Encode.map(
      %{
        current_page: Map.get(value, :current_page),
        page_size: Map.get(value, :page_size),
        total_count: Map.get(value, :total_count),
        total_pages: Map.get(value, :total_pages),
        has_next_page: Map.get(value, :has_next_page?),
        has_previous_page: Map.get(value, :has_previous_page?),
        next_page: Map.get(value, :next_page),
        previous_page: Map.get(value, :previous_page),
        filters: value |> Map.get(:flop) |> Map.get(:filters) |> Enum.map(&map_filter/1)
      },
      opts
    )
  end

  defp map_filter(filter) do
    %{
      field: filter.field,
      op: filter.op,
      value: filter.value
    }
  end
end
