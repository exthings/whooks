defmodule Whooks.Common.Ecto do
  alias Whooks.Repo

  require Logger

  def preload({:ok, entity}, preloads) do
    {:ok, Repo.preload(entity, preloads)}
  end

  def preload({:error, error}, _) do
    {:error, error}
  end

  def map_if_loaded(value, fun) do
    case value do
      %Ecto.Association.NotLoaded{} -> nil
      value when is_list(value) -> Enum.map(value, fun)
      value -> fun.(value)
    end
  end
end
