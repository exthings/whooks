defmodule WhooksWeb.OrganizationSettingsControllerTest do
  use WhooksWeb.ConnCase, async: true

  import Whooks.OrganizationsFixtures
  import Whooks.AuthFixtures
  alias Whooks.Organizations

  setup do
    org = organization_fixture(%{name: "Settings Test Org", event_retention_days: 15})
    root_user = user_fixture(%{role: "root"})
    support_user = user_fixture(%{role: "support"})

    %{org: org, root_user: root_user, support_user: support_user}
  end

  describe "GET /ui/admin/:organization_id/settings" do
    test "renders settings page for root user", %{conn: conn, org: org, root_user: root_user} do
      conn =
        conn
        |> log_in_user(root_user)
        |> get(~p"/ui/admin/#{org.id}/settings")

      assert conn.status == 200
    end

    test "redirects unauthenticated user to login", %{conn: conn, org: org} do
      conn = get(conn, ~p"/ui/admin/#{org.id}/settings")
      assert redirected_to(conn) == ~p"/ui/auth/login"
    end
  end

  describe "PUT /ui/admin/:organization_id/settings" do
    test "updates name and event_retention_days with valid params", %{
      conn: conn,
      org: org,
      root_user: root_user
    } do
      conn =
        conn
        |> log_in_user(root_user)
        |> put(~p"/ui/admin/#{org.id}/settings", %{
          "name" => "Updated Name",
          "event_retention_days" => "45"
        })

      assert redirected_to(conn) == ~p"/ui/admin/#{org.id}/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "settings updated successfully"

      updated = Organizations.get!(org.id)
      assert updated.name == "Updated Name"
      assert updated.event_retention_days == 45
    end

    test "sanitizes empty string to nil (indefinite retention)", %{
      conn: conn,
      org: org,
      root_user: root_user
    } do
      conn =
        conn
        |> log_in_user(root_user)
        |> put(~p"/ui/admin/#{org.id}/settings", %{
          "name" => "No Retention Org",
          "event_retention_days" => ""
        })

      assert redirected_to(conn) == ~p"/ui/admin/#{org.id}/settings"

      updated = Organizations.get!(org.id)
      assert updated.event_retention_days == nil
    end

    test "returns changeset errors on invalid values", %{
      conn: conn,
      org: org,
      root_user: root_user
    } do
      conn =
        conn
        |> log_in_user(root_user)
        |> put(~p"/ui/admin/#{org.id}/settings", %{
          "name" => "",
          "event_retention_days" => "-5"
        })

      assert redirected_to(conn) == ~p"/ui/admin/#{org.id}/settings"
    end

    test "forbids non-root user from updating settings", %{
      conn: conn,
      org: org,
      support_user: support_user
    } do
      conn =
        conn
        |> log_in_user(support_user)
        |> put(~p"/ui/admin/#{org.id}/settings", %{
          "name" => "Hacked Name"
        })

      assert conn.status == 403
    end
  end
end
