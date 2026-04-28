defmodule WhooksWeb.Plugs.UISharedProps do
  use WhooksWeb, :verified_routes

  import Plug.Conn
  import Inertia.Controller
  import Phoenix.Controller

  alias Whooks.Organizations
  alias Whooks.Serializer

  require Logger

  def fetch_organizations(conn, _opts) do
    Logger.info("PLUG: fetching organizations")
    user = conn.assigns.current_scope.user

    if user.role in [:root, :admin, :support] do
      conn
      |> assign_prop(
        :organizations,
        inertia_once(fn ->
          {:ok, {organizations, meta}} =
            Organizations.list(Map.get(conn.params, "organizations", %{}))

          %{data: Serializer.to_map(organizations), meta: Serializer.to_map(meta)}
        end)
      )
      |> assign_prop(:organization_id, Map.get(conn.params, "organization_id"))
    else
      conn
    end
  end
end
