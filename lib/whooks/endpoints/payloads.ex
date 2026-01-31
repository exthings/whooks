defmodule Whooks.Endpoints.Payloads do
  defmodule CreateEndpoint do
    defstruct [
      :consumer_id,
      :project_id,
      :uid,
      :status,
      :url,
      :description,
      :metadata,
      :headers,
      :subscribe
    ]
  end
end
