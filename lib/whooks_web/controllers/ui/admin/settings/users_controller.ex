defmodule WhooksWeb.UI.Admin.Settings.UsersController do
  use WhooksWeb, :controller

  alias Whooks.Auth
  alias Whooks.Serializer

  def index(conn, params) do
    conn
    |> assign_users_prop(params)
    |> assign_prop(:user, nil)
    |> assign_prop(:id, nil)
    |> render_inertia("settings/users/index")
  end

  def show(conn, params) do
    conn
    |> assign_users_prop(params)
    |> assign_prop(:user, fn ->
      Auth.get_user!(params["id"])
      |> case do
        nil -> nil
        user -> Serializer.to_map(user)
      end
    end)
    |> assign_prop(:id, params["id"])
    |> render_inertia("settings/users/index")
  end

  def create(conn, params) do
    with {:ok, user} <- Auth.create_user(params) do
      conn
      |> redirect(to: ~p"/ui/admin/settings/users/#{user.id}")
    else
      {:error, changeset} ->
        conn
        |> assign_errors(changeset)
        |> redirect(to: ~p"/ui/admin/settings/users")
    end
  end

  def update(conn, params) do
    with {:ok, user} <- Auth.update_user(params["id"], params) do
      conn
      |> redirect(to: ~p"/ui/admin/settings/users/#{user.id}")
    else
      {:error, changeset} ->
        conn
        |> assign_errors(changeset)
        |> redirect(to: ~p"/ui/admin/settings/users")
    end
  end

  defp assign_users_prop(conn, params) do
    conn
    |> assign_prop(:users, fn ->
      Auth.list_users(params)
      |> case do
        {:ok, {users, meta}} -> %{data: Serializer.to_map(users), meta: Serializer.to_map(meta)}
        {:error, _} -> %{data: [], meta: %{}}
      end
    end)
  end
end
