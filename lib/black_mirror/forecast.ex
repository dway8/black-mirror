defmodule BlackMirror.Forecast do
  require Logger

  def fetch do
    Logger.info("[Forecast] Updating weather")
    key = "58f1906f087041bc88a145330232506"
    url = "http://api.weatherapi.com/v1/forecast.json?key=#{key}&q=Lyon"

    url
    |> BlackMirror.HTTP.get()
    |> parse_response()
  end

  defp parse_response({:ok, %{body: body, status: 200}}) do
    # IO.puts(body)
    decoded = Jason.decode!(body)
    current = decoded["current"]
    current["temp_c"]
  end

  defp parse_response(_resp) do
    Logger.error("[Forecast] Received NOK response")
    0
  end
end
