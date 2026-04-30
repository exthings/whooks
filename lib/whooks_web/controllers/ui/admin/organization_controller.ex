defmodule WhooksWeb.UI.Admin.OrganizationController do
  use WhooksWeb, :controller

  alias Whooks.Organizations
  alias Whooks.Organizations.Organization
  alias Whooks.Serializer

  action_fallback WhooksWeb.UI.FallbackController

  require Logger

  def index(conn, params) do
    with :ok <- Bodyguard.permit(Organizations, :list, conn.assigns.current_scope, []),
         {:ok, {organizations, meta}} <- Organizations.list(params) do
      conn
      |> assign_prop(:organizations, %{
        data: Serializer.to_map(organizations),
        meta: Serializer.to_map(meta)
      })
      |> assign_prop(:id, params["id"])
      |> render_inertia("organizations/index")
    end
  end

  def create(conn, params) do
    Logger.info("Creating organization with params: #{inspect(params)}")

    with :ok <- Bodyguard.permit(Organizations, :create, conn.assigns.current_scope, []),
         {:ok, %Organization{} = _organization} <-
           Organizations.create_organization(params) do
      conn
      |> put_flash(:info, "Organization created successfully")
      |> redirect(to: ~p"/ui/admin/home")
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> assign_errors(changeset)
        |> redirect(to: ~p"/ui/admin/home")
    end
  end
end
