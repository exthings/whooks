defmodule Whooks.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Whooks.Projects` context.
  """

  @doc """
  Generate a project.
  """

  require Logger

  def project_fixture(attrs \\ %{}) do
    Logger.info("fixture  #{inspect(attrs)}")

    {:ok, project} =
      attrs
      |> Enum.into(%{
        organization_id: attrs[:organization_id],
        name: "some name",
        metadata: %{}
      })
      |> Whooks.Projects.create()

    project
  end
end
