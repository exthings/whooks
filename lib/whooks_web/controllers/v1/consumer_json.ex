defmodule WhooksWeb.V1.ConsumerJSON do
  alias Whooks.Consumers.Consumer

  @doc """
  Renders a list of consumers.
  """
  def index(%{consumers: consumers}) do
    %{data: for(consumer <- consumers, do: data(consumer))}
  end

  @doc """
  Renders a single consumer.
  """
  def show(%{consumer: consumer}) do
    %{data: data(consumer)}
  end

  defp data(%Consumer{} = consumer) do
    %{
      id: consumer.id,
      uid: consumer.uid,
      name: consumer.name,
      metadata: consumer.metadata
    }
  end
end
