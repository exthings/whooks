defmodule WhooksWeb.Plugs.GlobalFilters do
  import Plug.Conn
  import Inertia.Controller

  require Logger

  def init(default), do: default

  def call(%Plug.Conn{params: params} = conn, _default) do
    last = Map.get(params, "last", "1h")
    interval = Map.get(params, "interval", "minute")

    Logger.info("[Plugs.GlobalFilters] last: #{params["last"]}, interval: #{params["interval"]}")

    conn
    |> assign(:global_filters, %{last: last, interval: interval})
    |> assign_prop(:global_filters, %{last: last, interval: interval})
  end
end
