defmodule WhooksWeb.V1.ConsumerController do
  use WhooksWeb, :controller

  alias Whooks.Consumers
  alias Whooks.Consumers.Consumer

  action_fallback WhooksWeb.FallbackController

  def index(conn, _params) do
    consumers = Consumers.list_consumers()
    render(conn, :index, consumers: consumers)
  end

  def create(conn, params) do
    with {:ok, %Consumer{} = consumer} <- Consumers.create_consumer(params) do
      conn
      |> put_status(:created)
      |> render(:show, consumer: consumer)
    end
  end

  def show(conn, %{"id" => id}) do
    consumer = Consumers.get_consumer!(id)
    render(conn, :show, consumer: consumer)
  end

  def update(conn, %{"id" => id, "consumer" => consumer_params}) do
    consumer = Consumers.get_consumer!(id)

    with {:ok, %Consumer{} = consumer} <- Consumers.update_consumer(consumer, consumer_params) do
      render(conn, :show, consumer: consumer)
    end
  end

  def delete(conn, %{"id" => id}) do
    consumer = Consumers.get_consumer!(id)

    with {:ok, %Consumer{}} <- Consumers.delete_consumer(consumer) do
      send_resp(conn, :no_content, "")
    end
  end
end
