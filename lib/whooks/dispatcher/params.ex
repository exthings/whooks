defmodule Whooks.Dispatcher.Params do
  @type t :: %__MODULE__{
          event_id: String.t(),
          topic: String.t(),
          data: map(),
          timestamp: DateTime.t(),
          metadata: map()
        }

  defstruct [
    :event_id,
    :topic,
    :data,
    :timestamp,
    :metadata
  ]
end
