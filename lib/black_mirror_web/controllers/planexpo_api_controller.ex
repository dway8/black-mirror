defmodule BlackMirrorWeb.PlanexpoAPIController do
  use BlackMirrorWeb, :controller
  alias BlackMirror.Planexpo
  require Logger

  def refresh(conn, _params) do
    IO.puts("[Planexpo] Refresh")

    case Planexpo.refresh_year_deals() do
      :ok ->
        send_resp(conn, :ok, "")

      {error_code, error_message} ->
        send_resp(conn, error_code, error_message)
    end

    # events_list = Map.get(params, "events")

    # case MyBrocanteEvent.refresh_year_events(events_list) do
    #   {:ok, _} ->
    #     BlackMirror.MyBrocanteEvent.notify_subscribers(:events_updated)
    #     send_resp(conn, :ok, "")

    #   {:error, _} ->
    #     IO.puts(
    #       "[MyBrocante API] No events were created when refreshing year events. Params received were:"
    #     )

    #     IO.inspect(params)

    #     send_resp(conn, :bad_request, "")
    # end
  end
end
