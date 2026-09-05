defmodule WhooksWeb.UI.Consumer.HomeControllerTest do
  use WhooksWeb.ConnCase, async: true

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures

  setup do
    organization = organization_fixture()
    consumer = consumer_fixture(%{organization_id: organization.id})
    project = project_fixture(%{organization_id: organization.id})

    token = Whooks.Auth.generate_consumer_session_token(consumer)

    conn =
      Phoenix.ConnTest.build_conn()
      |> Phoenix.ConnTest.init_test_session(%{access_token: token})

    %{conn: conn, organization: organization, consumer: consumer, project: project}
  end

  import Inertia.Testing

  describe "GET /ui/consumers/dashboard" do
    test "renders dashboard page with initial props", %{conn: conn, project: _project} do
      conn = get(conn, ~p"/ui/consumers/dashboard")
      assert html_response(conn, 200) =~ "consumers/portal/dashboard"
      assert inertia_component(conn) == "consumers/portal/dashboard"
    end

    test "accepts filter parameters and exposes filters and projects props", %{
      conn: conn,
      project: project
    } do
      conn = get(conn, ~p"/ui/consumers/dashboard?last=7d&project_id=#{project.id}")
      assert html_response(conn, 200)
      props = inertia_props(conn)
      assert props.filters.last == "7d"
      assert props.filters.projectId == to_string(project.id)
      assert is_list(props.projects)
    end

    test "resolves deferred props successfully", %{conn: conn} do
      version =
        ["/assets/app.js"]
        |> Enum.map_join(&WhooksWeb.Endpoint.static_path(&1))
        |> then(&Base.encode16(:crypto.hash(:md5, &1), case: :lower))

      conn =
        conn
        |> put_req_header("x-inertia", "true")
        |> put_req_header("x-inertia-version", version)
        |> put_req_header("x-inertia-partial-component", "consumers/portal/dashboard")
        |> put_req_header(
          "x-inertia-partial-data",
          "kpis,eventsMetrics,events,endpointHealth"
        )
        |> get(~p"/ui/consumers/dashboard")

      assert conn.status == 200
      props = json_response(conn, 200)["props"]
      assert is_map(props["kpis"])
      assert is_map(props["eventsMetrics"])
      assert is_map(props["events"])
      assert is_list(props["events"]["data"])
      assert is_list(props["endpointHealth"])
    end
  end
end
