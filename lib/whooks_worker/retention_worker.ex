defmodule WhooksWorker.RetentionWorker do
  @moduledoc """
  Deprecated: Use `WhooksWorker.SchedulerWorker` instead.
  """

  defdelegate process(job), to: WhooksWorker.SchedulerWorker
end
