defmodule WhooksWeb.V1.TopicJSON do
  alias Whooks.Topics.Topic

  @doc """
  Renders a list of topics.
  """
  def index(%{topics: topics}) do
    %{data: for(topic <- topics, do: data(topic))}
  end

  @doc """
  Renders a single topic.
  """
  def show(%{topic: topic}) do
    %{data: data(topic)}
  end

  defp data(%Topic{} = topic) do
    %{
      id: topic.id,
      name: topic.name,
      status: topic.status,
      description: topic.description,
      json_schema: topic.json_schema
    }
  end
end
