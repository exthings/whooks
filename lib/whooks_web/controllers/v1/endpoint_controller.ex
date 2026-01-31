defmodule WhooksWeb.V1.EndpointController do
  use WhooksWeb, :controller

  alias Whooks.Endpoints
  alias Whooks.Endpoints.Endpoint
  alias Whooks.Endpoints.Payloads

  action_fallback WhooksWeb.FallbackController

  def index(conn, _params) do
    endpoints = Endpoints.list_endpoints()
    render(conn, :index, endpoints: endpoints)
  end

  def create(conn, params) do
    payload = %Payloads.CreateEndpoint{
      consumer_id: params["consumer_id"],
      project_id: params["project_id"],
      uid: params["uid"],
      status: params["status"],
      url: params["url"],
      description: params["description"],
      headers: params["headers"],
      metadata: params["metadata"],
      subscribe: params["subscribe"]
    }

    with {:ok, %Endpoint{} = endpoint} <- Endpoints.create_endpoint(payload) do
      conn
      |> put_status(:created)
      |> render(:show, endpoint: endpoint)
    end
  end

  def show(conn, %{"id" => id}) do
    endpoint = Endpoints.get_endpoint!(id)
    render(conn, :show, endpoint: endpoint)
  end

  def update(conn, %{"id" => id, "endpoint" => endpoint_params}) do
    endpoint = Endpoints.get_endpoint!(id)

    with {:ok, %Endpoint{} = endpoint} <- Endpoints.update_endpoint(endpoint, endpoint_params) do
      render(conn, :show, endpoint: endpoint)
    end
  end

  def delete(conn, %{"id" => id}) do
    endpoint = Endpoints.get_endpoint!(id)

    with {:ok, %Endpoint{}} <- Endpoints.delete_endpoint(endpoint) do
      send_resp(conn, :no_content, "")
    end
  end
end
