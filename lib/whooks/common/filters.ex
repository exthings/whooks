defmodule Whooks.Filters do
  import Ecto.Query

  def member_of(query, %Flop.Filter{value: value}, _opts) do
    where(
      query,
      [p],
      fragment("? MEMBER OF(?)", ^value, p.tags)
    )
  end
end
