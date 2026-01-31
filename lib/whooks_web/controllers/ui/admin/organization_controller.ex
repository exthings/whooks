defmodule WhooksWeb.UI.Admin.OrganizationController do
  use WhooksWeb, :controller

  alias Whooks.Organizations
  alias Whooks.Organizations.Organization

  def index(conn, params) do
    with {:ok, {organizations, meta}} <- Organizations.list(params) do
      conn
      |> assign_prop(:organizations, organizations)
      |> assign_prop(:meta, meta)
      |> assign_prop(:id, params["id"])
      |> render_inertia("organizations/index")
    end
  end
end
