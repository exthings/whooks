defmodule WhooksWeb.V1.OrganizationController do
  use WhooksWeb, :controller

  alias Whooks.Organizations
  alias Whooks.Organizations.Organization

  action_fallback WhooksWeb.FallbackController

  def index(conn, _params) do
    organizations = Organizations.list()
    render(conn, :index, organizations: organizations)
  end

  def create(conn, params) do
    with {:ok, %Organization{} = organization} <-
           Organizations.create(params) do
      conn
      |> put_status(:created)
      |> render(:show, organization: organization)
    end
  end

  def show(conn, %{"id" => id}) do
    organization = Organizations.get!(id)
    render(conn, :show, organization: organization)
  end

  def update(conn, %{"id" => id, "organization" => organization_params}) do
    organization = Organizations.get!(id)

    with {:ok, %Organization{} = organization} <-
           Organizations.update(organization, organization_params) do
      render(conn, :show, organization: organization)
    end
  end

  def delete(conn, %{"id" => id}) do
    organization = Organizations.get!(id)

    with {:ok, %Organization{}} <- Organizations.delete(organization) do
      send_resp(conn, :no_content, "")
    end
  end
end
