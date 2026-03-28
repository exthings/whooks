defmodule WhooksWeb.UI.Admin.OrganizationController do
  use WhooksWeb, :controller

  alias Whooks.Organizations
  alias Whooks.Organizations.Organization

  require Logger

  def index(conn, params) do
    with {:ok, {organizations, meta}} <- Organizations.list(params) do
      conn
      |> assign_prop(:organizations, organizations)
      |> assign_prop(:meta, meta)
      |> assign_prop(:id, params["id"])
      |> render_inertia("organizations/index")
    end
  end

  def create(conn, params) do
    Logger.info("Creating organization with params: #{inspect(params)}")

    with {:ok, %Organization{} = organization} <-
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
