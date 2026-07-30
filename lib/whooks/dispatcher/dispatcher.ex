defmodule Whooks.Dispatcher do
  @moduledoc """
  Strategy behaviour for dispatching events to different destinations.
  """

  alias Whooks.Dispatcher.Params
  alias Whooks.Dispatcher.Result

  @doc """
  Dispatches the request (e.g. by making an HTTP request).
  """
  @callback dispatch(request :: Params.t()) :: {:ok, Result.t()} | {:error, Result.t()}

  @callback result_to_attempt_params(result :: Result.t()) :: map

  @doc """
  Returns the appropriate dispatcher module for the given type.
  """
  def get_dispatcher(:standard_webhooks), do: Whooks.Dispatcher.StandardWebhooksDispatcher
  def get_dispatcher(_), do: Whooks.Dispatcher.StandardWebhooksDispatcher
end
