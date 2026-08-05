defmodule WhooksWeb.V1.ConsumerController do
  use WhooksWeb, :controller

  alias Whooks.Consumers
  alias Whooks.Consumers.Consumer

  action_fallback WhooksWeb.FallbackController

  def index(conn, _params) do
    consumers = Consumers.list()
    render(conn, :index, consumers: consumers)
  end

  def create(conn, params) do
    with {:ok, %Consumer{} = consumer} <- Consumers.create(params) do
      conn
      |> put_status(:created)
      |> render(:show, consumer: consumer)
    end
  end

  def show(conn, %{"id" => id}) do
    consumer = Consumers.get!(id)
    render(conn, :show, consumer: consumer)
  end

  def update(conn, %{"id" => id, "consumer" => consumer_params}) do
    consumer = Consumers.get!(id)

    with {:ok, %Consumer{} = consumer} <- Consumers.update(consumer, consumer_params) do
      render(conn, :show, consumer: consumer)
    end
  end

  def delete(conn, %{"id" => id}) do
    consumer = Consumers.get!(id)

    with {:ok, %Consumer{}} <- Consumers.delete(consumer) do
      send_resp(conn, :no_content, "")
    end
  end
end
