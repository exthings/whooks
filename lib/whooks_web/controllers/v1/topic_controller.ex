defmodule WhooksWeb.V1.TopicController do
  use WhooksWeb, :controller

  alias Whooks.Topics
  alias Whooks.Topics.Topic

  action_fallback WhooksWeb.FallbackController

  def index(conn, _params) do
    topics = Topics.list_topics()
    render(conn, :index, topics: topics)
  end

  def create(conn, params) do
    with {:ok, %Topic{} = topic} <- Topics.create_topic(params) do
      conn
      |> put_status(:created)
      |> render(:show, topic: topic)
    end
  end

  def show(conn, %{"id" => id}) do
    topic = Topics.get_topic!(id)
    render(conn, :show, topic: topic)
  end
end
