defmodule Whooks.Common.Changeset do
  @regex_dot_notation ~r/^[a-z]+(\.[a-z]+)*$/

  def validate_dot_notation(changeset, field) do
    changeset
    |> Ecto.Changeset.validate_format(field, @regex_dot_notation, message: "invalid dot notation")
  end
end
