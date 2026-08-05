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

    test "list_projects/0 returns all projects", %{org: org} do
      project = project_fixture(%{organization_id: org.id})
      assert Projects.list_projects() == [project]
    end

    test "get_project!/1 returns the project with given id", %{org: org} do
      project = project_fixture(%{organization_id: org.id})
      assert Projects.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project", %{org: org} do
      valid_attrs = %{organization_id: org.id, name: "some name", metadata: %{}}

      assert {:ok, %Project{} = project} = Projects.create_project(valid_attrs)
      assert project.name == "some name"
      assert project.metadata == %{}
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project", %{org: org} do
      project = project_fixture(%{organization_id: org.id})
      update_attrs = %{name: "some updated name", metadata: %{}}

      assert {:ok, %Project{} = project} = Projects.update_project(project, update_attrs)
      assert project.name == "some updated name"
      assert project.metadata == %{}
    end

    test "update_project/2 with invalid data returns error changeset", %{org: org} do
      project = project_fixture(%{organization_id: org.id})
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(project, @invalid_attrs)
      assert project == Projects.get_project!(project.id)
    end

    test "delete_project/1 deletes the project", %{org: org} do
      project = project_fixture(%{organization_id: org.id})
      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset", %{org: org} do
      project = project_fixture(%{organization_id: org.id})
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end
end
