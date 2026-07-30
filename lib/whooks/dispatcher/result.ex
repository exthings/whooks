defmodule Whooks.Dispatcher.Result do
  @moduledoc """
  Standardized Output response representing the execution state of a dispatch operation.
  """

  @type status :: :success | :failed | :retrying

  @type t :: %__MODULE__{
          status: status(),
          error: String.t() | nil,
          response: map() | nil,
          metadata: map()
        }

  @enforce_keys [:status]
  defstruct [
    :status,
    :error,
    :response,
    :metadata
  ]

  @doc """
  Helper initializer to simplify successful results.
  """
  def success(response \\ nil, metadata \\ %{}) do
    %__MODULE__{
      status: :success,
      error: nil,
      response: response,
      metadata: metadata
    }
  end

  @doc """
  Helper initializer to simplify failed results.
  """
  def failed(reason, response \\ nil, metadata \\ %{}) do
    %__MODULE__{
      status: :failed,
      error: to_string(reason),
      response: response,
      metadata: metadata
    }
  end

  def retrying(reason, response \\ nil, metadata \\ %{}) do
    %__MODULE__{
      status: :retrying,
      error: to_string(reason),
      response: response,
      metadata: metadata
    }
  end
end
