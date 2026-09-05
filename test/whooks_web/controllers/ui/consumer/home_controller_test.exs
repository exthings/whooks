defmodule WhooksWeb.UI.Consumer.HomeControllerTest do
  use WhooksWeb.ConnCase, async: true

  import Whooks.OrganizationsFixtures
  import Whooks.ProjectsFixtures
  import Whooks.ConsumersFixtures

  setup %{conn: conn} do
    organization = organization_fixture()
    consumer = consumer_fixture(%{organization_id: organization.id})
    project = project_fixture(%{organization_id: organization.id})

    token = Whooks.Auth.generate_consumer_session_token(consumer)

    conn =
      conn
      |> init_test_session(%{access_token: token})

    %{conn: conn, organization: organization, consumer: consumer, project: project}
  end

  describe "GET /ui/consumers/dashboard" do
    test "renders dashboard component with initial props", %{conn: conn} do
      conn = get(conn, ~p"/ui/consumers/dashboard")

      assert inertia_component(conn) == "consumers/portal/dashboard"

      props = inertia_props(conn)
      assert %{filters: %{last: "24h", projectId: nil}, projects: projects} = props
      assert length(projects) >= 1

      # Deferred props must not be evaluated or included on initial render
      refute Map.has_key?(props, :kpis)
      refute Map.has_key?(props, :eventsMetrics)
      refute Map.has_key?(props, :events)
      refute Map.has_key?(props, :endpointHealth)
    end

    test "accepts filter parameters and passes them as camelized props", %{
      conn: conn,
      project: project
    } do
      project_id_str = to_string(project.id)
      project_id = project.id
      conn = get(conn, ~p"/ui/consumers/dashboard?last=7d&project_id=#{project_id_str}")

      assert inertia_component(conn) == "consumers/portal/dashboard"

      assert %{
               filters: %{last: "7d", projectId: ^project_id_str},
               projects: [%{id: ^project_id} | _]
             } = inertia_props(conn)
    end

    test "resolves deferred props on partial reload", %{conn: conn} do
      conn =
        conn
        |> inertia_partial_reload("consumers/portal/dashboard", [
          "kpis",
          "eventsMetrics",
          "events",
          "endpointHealth"
        ])
        |> get(~p"/ui/consumers/dashboard")

      assert conn.status == 200

      props = inertia_props(conn)

      assert %{
               kpis: %{
                 activeEndpointsCount: _,
                 failedEvents: _,
                 successRate: _,
                 successfulEvents: _,
                 totalEvents: _
               },
               eventsMetrics: %{data: _, interval: "hour", last: "24h"},
               events: %{data: events_data, meta: _},
               endpointHealth: endpoints
             } = props

      assert is_list(events_data)
      assert is_list(endpoints)
    end

    test "selectively resolves only requested deferred props", %{conn: conn} do
      conn =
        conn
        |> inertia_partial_reload("consumers/portal/dashboard", ["kpis"])
        |> get(~p"/ui/consumers/dashboard")

      assert conn.status == 200

      props = inertia_props(conn)
      assert Map.has_key?(props, :kpis)
      refute Map.has_key?(props, :eventsMetrics)
      refute Map.has_key?(props, :events)
      refute Map.has_key?(props, :endpointHealth)
    end
  end
end
