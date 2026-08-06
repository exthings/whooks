defmodule Whooks.OrganizationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Whooks.Organizations` context.
  """

  @doc """
  Generate a organization.
  """
  def organization_fixture(attrs \\ %{}) do
    {:ok, organization} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Whooks.Organizations.create()

    organization
  end
end
