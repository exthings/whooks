defmodule WhooksWeb.UI.Admin.HomeController do
  use WhooksWeb, :controller

  alias Whooks.Organizations
  alias Whooks.Serializer

  require Logger

  def home(conn, _params) do
    {:ok, {organizations, meta}} =
      Organizations.list(%{})

    Plug.Conn.get_req_header(conn, "x-organization-id")
    |> case do
      [organization_id] ->
        conn
        |> assign_prop(:organizations, %{
          data: Serializer.to_map(organizations),
          meta: Serializer.to_map(meta)
        })
        |> render_inertia("home")

      [] ->
        conn
        |> render_inertia("home")
    end
  end
end
