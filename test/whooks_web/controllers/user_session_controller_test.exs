defmodule WhooksWeb.UserSessionControllerTest do
  use WhooksWeb.ConnCase, async: true

  import Whooks.AuthFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /ui/auth/login" do
    test "renders login page", %{conn: conn} do
      conn = get(conn, ~p"/ui/auth/login")
      assert conn.status == 200
    end
  end

  describe "POST /ui/auth/login" do
    test "logs the user in with valid credentials", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        post(conn, ~p"/ui/auth/login", %{
          "email" => user.email,
          "password" => valid_user_password()
        })

      assert get_session(conn, :access_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        post(conn, ~p"/ui/auth/login", %{
          "email" => user.email,
          "password" => valid_user_password(),
          "remember_me" => "true"
        })

      assert conn.resp_cookies["_whooks_web_user_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/ui/auth/login", %{
          "email" => user.email,
          "password" => "invalid_password"
        })

      assert redirected_to(conn) == ~p"/ui/auth/login"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Invalid credentials."
    end
  end

  describe "DELETE /ui/auth/logout" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/ui/auth/logout")
      assert redirected_to(conn) == ~p"/ui/auth/login"
      refute get_session(conn, :access_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/ui/auth/logout")
      assert redirected_to(conn) == ~p"/ui/auth/login"
      refute get_session(conn, :access_token)
    end
  end
end
