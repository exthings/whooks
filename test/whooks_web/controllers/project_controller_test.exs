defmodule WhooksWeb.ProjectControllerTest do
  use WhooksWeb.ConnCase

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  alias Whooks.Projects.Project

  @invalid_attrs %{name: nil, metadata: nil}

  setup %{conn: conn} do
    api_key = System.get_env("API_KEY") || "c700skca022vq2ljsoujy6lp"

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{api_key}")

    organization = organization_fixture()

    {:ok, conn: conn, organization: organization}
  end

  describe "index" do
    test "lists all projects", %{conn: conn} do
      conn = get(conn, ~p"/v1/projects")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create project" do
    test "renders project when data is valid", %{conn: conn, organization: organization} do
      create_attrs = %{
        name: "some name",
        metadata: %{},
        organization_id: organization.id
      }

      conn = post(conn, ~p"/v1/projects", create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/v1/projects/#{id}")

      assert %{
               "id" => ^id,
               "metadata" => %{},
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/v1/projects", @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show project" do
    setup [:create_project]

    test "renders project", %{conn: conn, project: %Project{id: project_id}} do
      id = to_string(project_id)
      conn = get(conn, ~p"/v1/projects/#{id}")

      assert %{
               "id" => ^id,
               "metadata" => %{},
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end
  end

  defp create_project(%{organization: organization}) do
    project = project_fixture(%{organization_id: organization.id})

    %{project: project}
  end
end
