defmodule Whooks.StandardWebhooks do
  @secret_prefix "whsec_"
  @signature_identifier "v1"
  @tolerance 5 * 60

  @doc """
  Sign a Standard Webhook given an id, timestamp, payload and secret
  """
  @spec sign(
          id :: String.t(),
          timestamp :: integer(),
          payload :: binary(),
          secret :: binary()
        ) ::
          String.t()
  def sign(id, _timestamp, _payload, _secret) when not is_binary(id) do
    raise ArgumentError, message: "Message id must be a string"
  end

  def sign(_id, timestamp, _payload, _secret) when not is_integer(timestamp) do
    raise ArgumentError, message: "Message timestamp must be an integer"
  end

  def sign(_id, _timestamp, payload, _secret) when not is_binary(payload) do
    raise ArgumentError, message: "Message payload must be a binary"
  end

  def sign(_id, _timestamp, _payload, secret) when not is_binary(secret) do
    raise ArgumentError, message: "Secret must be a string"
  end

  def sign(id, timestamp, payload, @secret_prefix <> secret) do
    decoded_secret = Base.decode64!(secret)

    sign_with_version(id, timestamp, payload, decoded_secret)
  end

  def sign(id, timestamp, payload, secret) do
    sign_with_version(id, timestamp, payload, secret)
  end

  defp sign_with_version(id, timestamp, payload, secret) do
    validate_timestamp(timestamp)

    signature =
      to_sign(id, timestamp, payload)
      |> sign_and_encode(secret)

    "#{@signature_identifier},#{signature}"
  end

  defp to_sign(id, timestamp, payload) do
    "#{id}.#{timestamp}.#{payload}"
  end

  defp sign_and_encode(to_sign, secret) do
    :crypto.mac(:hmac, :sha256, secret, to_sign)
    |> Base.encode64()
    |> String.trim()
  end

  def validate_timestamp(timestamp) do
    now = :os.system_time(:second)

    cond do
      is_integer(timestamp) and timestamp > now + @tolerance ->
        raise ArgumentError, message: "Message timestamp too new"

      is_integer(timestamp) and timestamp < now - @tolerance ->
        raise ArgumentError, message: "Message timestamp too old"

      true ->
        :ok
    end
  end
end
