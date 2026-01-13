defmodule WhooksWeb.V1.ProjectController do
  use WhooksWeb, :controller

  alias Whooks.Projects
  alias Whooks.Projects.Project

  action_fallback WhooksWeb.FallbackController

  def index(conn, _params) do
    projects = Projects.list_projects()
    render(conn, :index, projects: projects)
  end

  def create(conn, params) do
    with {:ok, %Project{} = project} <- Projects.create_project(params) do
      conn
      |> put_status(:created)
      |> render(:show, project: project)
    end
  end

  def show(conn, %{"id" => id}) do
    project = Projects.get_project!(id)
    render(conn, :show, project: project)
  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    project = Projects.get_project!(id)

    with {:ok, %Project{} = project} <- Projects.update_project(project, project_params) do
      render(conn, :show, project: project)
    end
  end

  def delete(conn, %{"id" => id}) do
    project = Projects.get_project!(id)

    with {:ok, %Project{}} <- Projects.delete_project(project) do
      send_resp(conn, :no_content, "")
    end
  end
end
