defmodule WhooksWeb.UI.Admin.OrganizationSettingsController do
  use WhooksWeb, :controller

  alias Whooks.Organizations
  alias Whooks.Serializer

  action_fallback WhooksWeb.UI.FallbackController

  def show(conn, %{"organization_id" => org_id}) do
    organization = Organizations.get!(org_id)

    with :ok <- Bodyguard.permit(Organizations, :get, conn.assigns.current_scope, organization) do
      conn
      |> assign_prop(:organization, Serializer.to_map(organization))
      |> render_inertia("organizations/settings")
    end
  end

  def update(conn, %{"organization_id" => org_id} = params) do
    organization = Organizations.get!(org_id)

    with :ok <- Bodyguard.permit(Organizations, :update, conn.assigns.current_scope, organization) do
      org_params =
        params
        |> Map.take(["name", "event_retention_days"])
        |> sanitize_retention_days()

      case Organizations.update(organization, org_params) do
        {:ok, _updated} ->
          conn
          |> put_flash(:info, "Organization settings updated successfully")
          |> redirect(to: ~p"/ui/admin/#{org_id}/settings")

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> assign_errors(changeset)
          |> redirect(to: ~p"/ui/admin/#{org_id}/settings")
      end
    end
  end

  defp sanitize_retention_days(%{"event_retention_days" => val} = params)
       when val in ["", nil] do
    Map.put(params, "event_retention_days", nil)
  end

  defp sanitize_retention_days(params), do: params
end
