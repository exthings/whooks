defmodule WhooksWeb.Plugs.OrganizationsPropPlug do
  import Inertia.Controller
  import Phoenix.Controller
  import Plug.Conn

  alias Whooks.Organizations
  alias Whooks.Serializer

  def init(opts), do: opts

  def call(%Plug.Conn{} = conn, _opts) do
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
  end
end

defmodule WhooksWeb.Plugs.SelectOrganizationsPlug do
  import Inertia.Controller
  import Phoenix.Controller
  import Plug.Conn

  alias Whooks.Organizations
  alias Whooks.Serializer

  require Logger

  def init(opts), do: opts

  def call(%Plug.Conn{} = conn, _opts) do
    Logger.info("select org plug")

    header_org_id = get_organization_id_from_header(conn)
    params_org_id = get_organization_id_from_params(conn)

    Logger.info("header_org_id: #{inspect(header_org_id)}")
    Logger.info("params_org_id: #{inspect(params_org_id)}")

    conn
  end

  defp get_organization_id_from_header(conn) do
    Plug.Conn.get_req_header(conn, "x-organization-id")
    |> case do
      [organization_id] ->
        organization_id

      [] ->
        nil
    end
  end

  defp get_organization_id_from_params(conn) do
    Map.get(conn.params, "organization_id")
  end
end
