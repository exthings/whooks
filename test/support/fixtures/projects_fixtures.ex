defmodule Whooks.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Whooks.Projects` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        metadata: %{},
        name: "some name"
      })
      |> Whooks.Projects.create_project()

    project
  end
end
