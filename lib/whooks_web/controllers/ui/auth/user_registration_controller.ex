defmodule WhooksWeb.UI.Auth.UserRegistrationController do
  use WhooksWeb, :controller

  alias Whooks.Auth
  alias Whooks.Auth.User

  def new(conn, _params) do
    changeset = Auth.change_user_email(%User{})
    render(conn, :new, changeset: changeset)
  end

  def index(conn, _params) do
    conn
    |> render_inertia("auth/registration")
  end

  def create(conn, params) do
    case Auth.register_user(%{
           name: params["name"],
           email: params["email"],
           password: params["password"]
         }) do
      {:ok, user} ->
        conn
        |> put_flash(
          :info,
          "An email was sent to #{user.email}, please access it to confirm your account."
        )
        |> redirect(to: ~p"/ui/auth/login")

      {:error, changeset} ->
        conn
        |> assign_errors(changeset)
        |> redirect(to: ~p"/ui/auth/register")
    end
  end
end
