defmodule WhooksWorker.BulkWorker do
  @moduledoc """
  BullMQ worker processing asynchronous bulk event operations.
  """
  alias BullMQ.Job
  alias Whooks.Events.Bulk

  require Logger

  def process(%Job{name: name, data: data})
      when name in ["bulk_operation", "bulk_resend", "resend_batch"] do
    Logger.info("[BulkWorker.#{name}] Processing bulk job: #{inspect(data)}")
    Bulk.process(data)
  end

  def process(%Job{name: name}) do
    {:error, "Unknown job type: #{name}"}
  end
end
