defmodule WhooksWeb.UI.Admin.Settings.UsersControllerTest do
  use WhooksWeb.ConnCase

  import Whooks.AuthFixtures

  setup do
    root_user = user_fixture(%{role: "root"})
    other_user = user_fixture(%{role: "support"})

    %{root_user: root_user, other_user: other_user}
  end

  describe "GET /ui/admin/settings/users" do
    test "renders inertia page with users and current_user", %{conn: conn, root_user: root_user} do
      conn =
        conn
        |> log_in_user(root_user)
        |> get(~p"/ui/admin/settings/users")

      assert html_response(conn, 200) =~ "settings/users/index"
    end
  end

  describe "GET /ui/admin/settings/users/:id" do
    test "renders inertia page with specific user details", %{
      conn: conn,
      root_user: root_user,
      other_user: other_user
    } do
      conn =
        conn
        |> log_in_user(root_user)
        |> get(~p"/ui/admin/settings/users/#{other_user.id}")

      assert html_response(conn, 200) =~ "settings/users/index"
    end
  end

  describe "PUT /ui/admin/settings/users/:id" do
    test "updates role of another user successfully", %{
      conn: conn,
      root_user: root_user,
      other_user: other_user
    } do
      conn =
        conn
        |> log_in_user(root_user)
        |> put(~p"/ui/admin/settings/users/#{other_user.id}", %{"role" => "admin"})

      assert redirected_to(conn) == ~p"/ui/admin/settings/users/#{other_user.id}"
      assert Whooks.Auth.get_user!(other_user.id).role == :admin
    end

    test "rejects role change when root attempts self-demotion", %{
      conn: conn,
      root_user: root_user
    } do
      conn =
        conn
        |> log_in_user(root_user)
        |> put(~p"/ui/admin/settings/users/#{root_user.id}", %{"role" => "admin"})

      assert redirected_to(conn) == ~p"/ui/admin/settings/users/#{root_user.id}"
      assert Whooks.Auth.get_user!(root_user.id).role == :root
    end
  end
end
