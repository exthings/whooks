defmodule Whooks.Common.Ecto do
  alias Whooks.Repo

  def preload({:ok, entity}, preloads) do
    {:ok, Repo.preload(entity, preloads)}
  end

  def preload({:error, error}, _) do
    {:error, error}
  end
end
