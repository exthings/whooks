defmodule WhooksWeb.UI.Admin.Settings.UsersController do
  use WhooksWeb, :controller

  alias Whooks.Auth
  alias Whooks.Serializer

  def index(conn, params) do
    conn
    |> assign_common(params)
    |> assign_users(params)
    |> assing_user(params)
    |> render_inertia("settings/users/index")
  end

  def show(conn, params) do
    conn
    |> assign_common(params)
    |> assign_users(params)
    |> assing_user(params)
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
    current_user = conn.assigns.current_scope.user

    with {:ok, user} <- Auth.update_user(current_user, params["id"], params) do
      conn
      |> redirect(to: ~p"/ui/admin/settings/users/#{user.id}")
    else
      {:error, changeset} ->
        conn
        |> assign_errors(changeset)
        |> redirect(to: ~p"/ui/admin/settings/users/#{params["id"]}")
    end
  end

  defp assign_common(conn, params) do
    conn
    |> assign_prop(:id, params["id"])
    |> assign_prop(:current_user, fn ->
      Serializer.to_map(conn.assigns.current_scope.user)
    end)
  end

  defp assing_user(conn, params) do
    conn
    |> assign_prop(:user, fn ->
      if params["id"] do
        Auth.get_user!(params["id"])
        |> case do
          nil -> nil
          user -> Serializer.to_map(user)
        end
      else
        nil
      end
    end)
  end

  defp assign_users(conn, params) do
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
