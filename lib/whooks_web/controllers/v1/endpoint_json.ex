defmodule WhooksWeb.V1.EndpointJSON do
  alias Whooks.Endpoints.Endpoint

  @doc """
  Renders a list of endpoints.
  """
  def index(%{endpoints: endpoints}) do
    %{data: for(endpoint <- endpoints, do: data(endpoint))}
  end

  @doc """
  Renders a single endpoint.
  """
  def show(%{endpoint: endpoint}) do
    %{data: data(endpoint)}
  end

  defp data(%Endpoint{} = endpoint) do
    %{
      id: endpoint.id,
      uid: endpoint.uid,
      status: endpoint.status,
      url: endpoint.url,
      description: endpoint.description,
      headers: endpoint.headers,
      metadata: endpoint.metadata,
      secret: endpoint.secret,
      old_secrets: endpoint.old_secrets
    }
  end
end
