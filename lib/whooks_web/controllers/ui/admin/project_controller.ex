defmodule WhooksWeb.UI.Admin.ProjectController do
  use WhooksWeb, :controller

  alias Whooks.Projects

  def index(conn, params) do
    with {:ok, {projects, meta}} <- Projects.list(params) do
      conn
      |> assign_prop(:projects, projects)
      |> assign_prop(:meta, meta)
      |> assign_prop(:id, params["id"])
      |> render_inertia("projects/index")
    end
  end
end
