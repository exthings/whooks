defmodule Whooks.Filters do
  import Ecto.Query

  def member_of(query, %Flop.Filter{value: value}, _opts) do
    where(
      query,
      [p],
      fragment("? MEMBER OF(?)", ^value, p.tags)
    )
  end

  def ilike(query, %Flop.Filter{value: value, field: field}, _opts) do
    pattern = "%#{value}%"
    where(query, [p], fragment("? ILIKE ?", field(p, ^field), ^pattern))
  end

  def name_field(_opts) do
    dynamic([p], p.name)
  end
end
