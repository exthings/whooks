defmodule WhooksWeb.OrganizationControllerTest do
  use WhooksWeb.ConnCase

  import Whooks.OrganizationsFixtures
  alias Whooks.Organizations.Organization

  @create_attrs %{
    name: "some name"
  }
  @invalid_attrs %{name: nil}

  setup %{conn: conn} do
    api_key = System.get_env("API_KEY") || "c700skca022vq2ljsoujy6lp"

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{api_key}")

    {:ok, conn: conn}
  end

  describe "index" do
    test "lists all organizations", %{conn: conn} do
      conn = get(conn, ~p"/v1/organizations")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create organization" do
    test "renders organization when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/v1/organizations", @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/v1/organizations/#{id}")

      assert %{
               "id" => ^id,
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/v1/organizations", @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show organization" do
    setup [:create_organization]

    test "renders organization", %{conn: conn, organization: %Organization{id: organization_id}} do
      id = to_string(organization_id)
      conn = get(conn, ~p"/v1/organizations/#{id}")

      assert %{
               "id" => ^id,
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end
  end

  defp create_organization(_) do
    organization = organization_fixture()

    %{organization: organization}
  end
end
