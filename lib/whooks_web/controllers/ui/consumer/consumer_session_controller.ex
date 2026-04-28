defmodule WhooksWeb.UI.Consumer.ConsumerSessionController do
  use WhooksWeb, :controller

  alias Whooks.Auth
  alias WhooksWeb.Plugs

  require Logger

  def confirm(conn, params) do
    Logger.info("Confirming consumer session for token: #{params["token"]}")

    case Auth.login_consumer_by_token(params["token"]) do
      {:ok, {consumer, _expired_tokens}} ->
        conn
        |> Plugs.Auth.log_in_consumer(consumer, params)
        |> redirect(to: ~p"/ui/consumers")

      {:error, :not_found} ->
        Logger.info("Consumer session not found for token: #{params["token"]}")

        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> render(:new, form: Phoenix.Component.to_form(%{}, as: "user"))
    end
  end
end
