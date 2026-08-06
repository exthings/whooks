defmodule Whooks.ProjectsTest do
  use Whooks.DataCase

  alias Whooks.Projects

  describe "projects" do
    alias Whooks.Projects.Project

    import Whooks.OrganizationsFixtures
    import Whooks.ProjectsFixtures

    @invalid_attrs %{name: nil, metadata: nil}

    setup do
      org = organization_fixture()

      %{org: org}
    end

    test "list/0 returns all projects", %{org: org} do
      project = project_fixture(%{organization_id: org.id})
      assert Projects.list() == [project]
    end

    test "get!/1 returns the project with given id", %{org: org} do
      project = project_fixture(%{organization_id: org.id})
      assert Projects.get!(project.id) == project
    end

    test "create/1 with valid data creates a project", %{org: org} do
      valid_attrs = %{organization_id: org.id, name: "some name", metadata: %{}}

      assert {:ok, %Project{} = project} = Projects.create(valid_attrs)
      assert project.name == "some name"
      assert project.metadata == %{}
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the project", %{org: org} do
      project = project_fixture(%{organization_id: org.id})
      update_attrs = %{name: "some updated name", metadata: %{}}

      assert {:ok, %Project{} = project} = Projects.update(project, update_attrs)
      assert project.name == "some updated name"
      assert project.metadata == %{}
    end

    test "update/2 with invalid data returns error changeset", %{org: org} do
      project = project_fixture(%{organization_id: org.id})
      assert {:error, %Ecto.Changeset{}} = Projects.update(project, @invalid_attrs)
      assert project == Projects.get!(project.id)
    end

    test "delete/1 deletes the project", %{org: org} do
      project = project_fixture(%{organization_id: org.id})
      assert {:ok, %Project{}} = Projects.delete(project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get!(project.id) end
    end

    test "change/1 returns a project changeset", %{org: org} do
      project = project_fixture(%{organization_id: org.id})
      assert %Ecto.Changeset{} = Projects.change(project)
    end
  end
end
