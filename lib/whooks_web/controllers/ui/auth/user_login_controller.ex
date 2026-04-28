defmodule WhooksWeb.UI.Auth.UserLoginController do
  use WhooksWeb, :controller

  alias Whooks.Auth
  alias Whooks.Auth.User
  alias WhooksWeb.Plugs

  def index(conn, _params) do
    conn
    |> render_inertia("auth/login")
  end

  def create(conn, params) do
    if user = Auth.get_user_by_email_and_password(params["email"], params["password"]) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> Plugs.Auth.log_in_user(user, params)
      |> redirect(to: ~p"/ui/admin/home")
    else
      conn
      |> put_flash(:error, "Invalid credentials.")
      |> redirect(to: ~p"/ui/auth/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> Plugs.Auth.log_out_user()
  end
end
