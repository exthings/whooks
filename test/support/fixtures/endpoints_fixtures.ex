defmodule Whooks.EndpointsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Whooks.Endpoints` context.
  """

  @doc """
  Generate a unique endpoint uid.
  """

  @doc """
  Generate a endpoint.
  """
  def endpoint_fixture(attrs \\ %{}) do
    {:ok, endpoint} =
      attrs
      |> Enum.into(%{
        description: "Localhost endpoint",
        headers: %{},
        metadata: %{},
        old_secrets: %{},
        secret: "some secret",
        status: "enabled",
        url: "http://localhost:4001"
      })
      |> Whooks.Endpoints.create_endpoint()

    endpoint
  end
end
