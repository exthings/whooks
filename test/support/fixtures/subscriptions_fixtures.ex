defmodule Whooks.SubscriptionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Whooks.Subscriptions` context.
  """

  @doc """
  Generate a subscription.
  """
  def subscription_fixture(attrs \\ %{}) do
    {:ok, subscription} =
      attrs
      |> Enum.into(%{
        status: "some status"
      })
      |> Whooks.Subscriptions.create_subscription()

    subscription
  end
end
