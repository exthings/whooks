defmodule WhooksWeb.Plugs.AuthTest do
  use WhooksWeb.ConnCase, async: true

  alias Whooks.Auth
  alias Whooks.Auth.Scope
  alias WhooksWeb.Plugs

  import Whooks.AuthFixtures
  import Whooks.ConsumersFixtures

  @remember_me_cookie "_whooks_web_user_remember_me"
  @remember_me_cookie_max_age 60 * 60 * 24 * 14

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, WhooksWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: %{user_fixture() | authenticated_at: DateTime.utc_now(:second)}, conn: conn}
  end

  describe "log_in_user/3" do
    test "stores the user token in the session", %{conn: conn, user: user} do
      conn = Plugs.Auth.log_in_user(conn, user)
      assert token = get_session(conn, :access_token)
      assert redirected_to(conn) == ~p"/"
      assert Auth.get_user_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, user: user} do
      conn = conn |> put_session(:to_be_removed, "value") |> Plugs.Auth.log_in_user(user)
      refute get_session(conn, :to_be_removed)
    end

    test "keeps session when re-authenticating", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> put_session(:to_be_removed, "value")
        |> Plugs.Auth.log_in_user(user)

      assert get_session(conn, :to_be_removed)
    end

    test "clears session when user does not match when re-authenticating", %{
      conn: conn,
      user: user
    } do
      other_user = user_fixture()

      conn =
        conn
        |> assign(:current_scope, Scope.for_user(other_user))
        |> put_session(:to_be_removed, "value")
        |> Plugs.Auth.log_in_user(user)

      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, user: user} do
      conn = conn |> put_session(:user_return_to, "/hello") |> Plugs.Auth.log_in_user(user)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, user: user} do
      conn = conn |> fetch_cookies() |> Plugs.Auth.log_in_user(user, %{"remember_me" => "true"})
      assert get_session(conn, :access_token) == conn.cookies[@remember_me_cookie]
      assert get_session(conn, :user_remember_me) == true

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :access_token)
      assert max_age == @remember_me_cookie_max_age
    end

    test "writes a cookie if remember_me was set in previous session", %{conn: conn, user: user} do
      conn = conn |> fetch_cookies() |> Plugs.Auth.log_in_user(user, %{"remember_me" => "true"})
      assert get_session(conn, :access_token) == conn.cookies[@remember_me_cookie]
      assert get_session(conn, :user_remember_me) == true

      conn =
        conn
        |> recycle()
        |> Map.replace!(:secret_key_base, WhooksWeb.Endpoint.config(:secret_key_base))
        |> fetch_cookies()
        |> init_test_session(%{user_remember_me: true})

      # the conn is already logged in and has the remember_me cookie set,
      # now we log in again and even without explicitly setting remember_me,
      # the cookie should be set again
      conn = conn |> Plugs.Auth.log_in_user(user, %{})
      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :access_token)
      assert max_age == @remember_me_cookie_max_age
      assert get_session(conn, :user_remember_me) == true
    end
  end

  describe "log_in_consumer/3" do
    test "stores the consumer token in the session", %{conn: conn} do
      consumer = consumer_fixture()
      conn = Plugs.Auth.log_in_consumer(conn, consumer)
      assert token = get_session(conn, :access_token)
      assert {retrieved_consumer, _token_inserted_at} = Auth.get_consumer_by_session_token(token)
      assert retrieved_consumer.id == consumer.id
    end
  end

  describe "logout_user/1" do
    test "erases session and cookies", %{conn: conn, user: user} do
      user_token = Auth.generate_user_session_token(user)

      conn =
        conn
        |> put_session(:access_token, user_token)
        |> put_req_cookie(@remember_me_cookie, user_token)
        |> fetch_cookies()
        |> Plugs.Auth.log_out_user()

      refute get_session(conn, :access_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/ui/auth/login"
      refute Auth.get_user_by_session_token(user_token)
    end

    test "works even if user is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> Plugs.Auth.log_out_user()
      refute get_session(conn, :access_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/ui/auth/login"
    end

    test "broadcasts disconnect event when live_socket_id is set in session", %{conn: conn} do
      live_socket_id = "users_sessions:123"
      WhooksWeb.Endpoint.subscribe(live_socket_id)

      conn =
        conn
        |> put_session(:live_socket_id, live_socket_id)
        |> fetch_cookies()
        |> Plugs.Auth.log_out_user()

      assert_receive %Phoenix.Socket.Broadcast{topic: ^live_socket_id, event: "disconnect"}
      assert redirected_to(conn) == ~p"/ui/auth/login"
    end
  end

  describe "fetch_current_scope_for_user/2" do
    test "authenticates user from session", %{conn: conn, user: user} do
      user_token = Auth.generate_user_session_token(user)

      conn =
        conn
        |> put_session(:access_token, user_token)
        |> Plugs.Auth.fetch_current_scope_for_user([])

      assert conn.assigns.current_scope.user.id == user.id
      assert conn.assigns.current_scope.user.authenticated_at == user.authenticated_at
      assert get_session(conn, :access_token) == user_token
    end

    test "authenticates user from cookies", %{conn: conn, user: user} do
      logged_in_conn =
        conn |> fetch_cookies() |> Plugs.Auth.log_in_user(user, %{"remember_me" => "true"})

      user_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> Plugs.Auth.fetch_current_scope_for_user([])

      assert conn.assigns.current_scope.user.id == user.id
      assert conn.assigns.current_scope.user.authenticated_at == user.authenticated_at
      assert get_session(conn, :access_token) == user_token
      assert get_session(conn, :user_remember_me)
    end

    test "does not authenticate if data is missing", %{conn: conn, user: user} do
      _ = Auth.generate_user_session_token(user)
      conn = Plugs.Auth.fetch_current_scope_for_user(conn, [])
      refute get_session(conn, :access_token)
      refute conn.assigns.current_scope
    end

    test "reissues a new token after a few days and refreshes cookie", %{conn: conn, user: user} do
      logged_in_conn =
        conn |> fetch_cookies() |> Plugs.Auth.log_in_user(user, %{"remember_me" => "true"})

      token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      offset_user_token(token, -10, :day)
      {user, _} = Auth.get_user_by_session_token(token)

      conn =
        conn
        |> put_session(:access_token, token)
        |> put_session(:user_remember_me, true)
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> Plugs.Auth.fetch_current_scope_for_user([])

      assert conn.assigns.current_scope.user.id == user.id
      assert conn.assigns.current_scope.user.authenticated_at == user.authenticated_at
      assert new_token = get_session(conn, :access_token)
      assert new_token != token
      assert %{value: new_signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert new_signed_token != signed_token
      assert max_age == @remember_me_cookie_max_age
    end

    test "assigns nil scope when session token is invalid", %{conn: conn} do
      conn =
        conn
        |> put_session(:access_token, "invalid_user_token")
        |> Plugs.Auth.fetch_current_scope_for_user([])

      refute conn.assigns.current_scope
    end
  end

  describe "fetch_current_scope_for_consumer/2" do
    test "authenticates consumer from session", %{conn: conn} do
      consumer = consumer_fixture()
      consumer_token = Auth.generate_consumer_session_token(consumer)

      conn =
        conn
        |> put_session(:access_token, consumer_token)
        |> Plugs.Auth.fetch_current_scope_for_consumer([])

      assert conn.assigns.current_scope.consumer.id == consumer.id
      assert get_session(conn, :access_token) == consumer_token
    end

    test "assigns nil scope when token is missing or invalid", %{conn: conn} do
      conn =
        conn
        |> put_session(:access_token, "invalid_consumer_token")
        |> Plugs.Auth.fetch_current_scope_for_consumer([])

      refute conn.assigns.current_scope
    end
  end

  describe "require_api_key/2" do
    setup do
      api_key = System.get_env("API_KEY") || "test_api_key_value"
      System.put_env("API_KEY", api_key)
      %{api_key: api_key}
    end

    test "authenticates when valid bearer token is provided", %{conn: conn, api_key: api_key} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> api_key)
        |> Plugs.Auth.require_api_key([])

      refute conn.halted
      assert conn.assigns.current_scope.user.email == Auth.build_root_user().email
    end

    test "returns 401 unauthorized when authorization header is missing", %{conn: conn} do
      conn = Plugs.Auth.require_api_key(conn, [])
      assert conn.halted
      assert conn.status == 401
      assert json_response(conn, 401) == %{"error" => "Unauthorized"}
    end

    test "returns 401 unauthorized when authorization header is not Bearer", %{
      conn: conn,
      api_key: api_key
    } do
      conn =
        conn
        |> put_req_header("authorization", "Basic " <> api_key)
        |> Plugs.Auth.require_api_key([])

      assert conn.halted
      assert conn.status == 401
      assert json_response(conn, 401) == %{"error" => "Unauthorized"}
    end

    test "returns 401 unauthorized when API key does not match env", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer wrong_api_key")
        |> Plugs.Auth.require_api_key([])

      assert conn.halted
      assert conn.status == 401
      assert json_response(conn, 401) == %{"error" => "Unauthorized"}
    end
  end

  describe "require_sudo_mode/2" do
    test "allows users that have authenticated in the last 10 minutes", %{conn: conn, user: user} do
      conn =
        conn
        |> fetch_flash()
        |> assign(:current_scope, Scope.for_user(user))
        |> Plugs.Auth.require_sudo_mode([])

      refute conn.halted
      refute conn.status
    end

    test "redirects when authentication is too old", %{conn: conn, user: user} do
      eleven_minutes_ago = DateTime.utc_now(:second) |> DateTime.add(-11, :minute)
      user = %{user | authenticated_at: eleven_minutes_ago}
      user_token = Auth.generate_user_session_token(user)
      {user, token_inserted_at} = Auth.get_user_by_session_token(user_token)
      assert DateTime.compare(token_inserted_at, user.authenticated_at) == :gt

      conn =
        conn
        |> fetch_flash()
        |> assign(:current_scope, Scope.for_user(user))
        |> Plugs.Auth.require_sudo_mode([])

      assert redirected_to(conn) == ~p"/users/log-in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must re-authenticate to access this page."
    end
  end

  describe "redirect_if_user_is_authenticated/2" do
    setup %{conn: conn} do
      %{conn: Plugs.Auth.fetch_current_scope_for_user(conn, [])}
    end

    test "redirects if user is authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> Plugs.Auth.redirect_if_user_is_authenticated([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if user is not authenticated", %{conn: conn} do
      conn = Plugs.Auth.redirect_if_user_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_user/2" do
    setup %{conn: conn} do
      %{conn: Plugs.Auth.fetch_current_scope_for_user(conn, [])}
    end

    test "redirects if user is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> Plugs.Auth.require_authenticated_user([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/ui/auth/login"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> Plugs.Auth.require_authenticated_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> Plugs.Auth.require_authenticated_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> Plugs.Auth.require_authenticated_user([])

      assert halted_conn.halted
      refute get_session(halted_conn, :user_return_to)
    end

    test "does not redirect if user is authenticated", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> Plugs.Auth.require_authenticated_user([])

      refute conn.halted
      refute conn.status
    end
  end
end
