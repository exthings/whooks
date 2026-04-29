defmodule WhooksWeb.Plugs.UISharedProps do
  use WhooksWeb, :verified_routes

  import Inertia.Controller

  alias Whooks.Organizations
  alias Whooks.Serializer

  require Logger

  def fetch_organizations(conn, _opts) do
    Logger.info("PLUG: fetching organizations")
    scope = conn.assigns.current_scope

    with :ok <- Bodyguard.permit(Whooks.Organizations, :list, scope, []) do
      conn
      |> assign_prop(
        :organizations,
        inertia_once(fn ->
          {:ok, {organizations, meta}} =
            Organizations.list(Map.get(conn.params, "organizations", %{}))

          %{data: Serializer.to_map(organizations), meta: Serializer.to_map(meta)}
        end)
      )
      |> assign_prop(:organization_id, conn.params["organization_id"])
    else
      _ ->
        conn
        |> assign_prop(
          :organization_id,
          conn.params["organization_id"]
        )
    end
  end
end
