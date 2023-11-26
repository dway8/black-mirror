defmodule BlackMirror.Planexpo do
  alias BlackMirror.Hubspot
  require Logger

  @new_client_deal "164778488"
  @renewal_deal "143427545"
  @upsell_deal "235302083"

  @spec refresh_year_deals() :: :ok | {atom(), String.t()}
  def refresh_year_deals() do
    case Hubspot.fetch_year_deals() do
      {:ok, deals} ->
        Logger.info("[Planexpo] Found #{length(deals)} deals")
        :ok

      {:bad_request, error_message} ->
        Logger.error("[Planexpo] Bad request when fetching Hubspot deals: #{error_message}")
        {:bad_request, error_message}

      {:unauthorized, error_message} ->
        Logger.error(
          "[Planexpo] Unauthorized ressource when fetching Hubspot deals: #{error_message}"
        )

        {:unauthorized, error_message}

      {:internal_server_error, error_message} ->
        Logger.error(
          "[Planexpo] Internal server error when fetching Hubspot deals: #{error_message}"
        )

        {:internal_server_error, error_message}
    end
  end
end
