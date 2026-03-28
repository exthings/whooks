defmodule WhooksWeb.UI.Admin.TopicController do
  use WhooksWeb, :controller

  alias Whooks.Topics
  alias Whooks.Topics.Topic

  require Logger

  def create(conn, params) do
    data = %{
      project_id: params["projectId"],
      name: params["name"],
      description: params["description"],
      status: params["status"],
      json_schema: params["jsonSchema"],
      example: params["example"]
    }

    Logger.info("Create topic data: #{inspect(data)}")

    with {:ok, %Topic{} = _topic} <- Topics.create_topic(data) do
      conn
      |> put_flash(:info, "Topic created successfully")
      |> redirect(to: ~p"/ui/admin/projects/#{data.project_id}")
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.info("Changeset: #{inspect(changeset)}")

        conn
        |> assign_errors(changeset)
        |> redirect(to: ~p"/ui/admin/projects/#{data.project_id}")
    end
  end
end
