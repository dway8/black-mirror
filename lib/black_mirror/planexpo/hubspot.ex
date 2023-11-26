defmodule BlackMirror.Hubspot do
  require Logger

  @api_token System.get_env("HUBSPOT_API_TOKEN")

  @spec fetch_year_deals(String.t() | nil, list(deal())) ::
          {:ok, list(deal())} | deals_response_failure()
  def fetch_year_deals(next \\ nil, deals_acc \\ []) do
    Logger.info("[Hubspot] Fetching year deals with next param #{next}")

    url =
      "https://api.hubapi.com/crm/v3/objects/deals?limit=100&archived=false&properties=amount,closedate,dealstage" <>
        if next === nil, do: "", else: "&after=" <> next

    resp =
      BlackMirror.HTTP.get(url, [
        {"Authorization", "Bearer #{@api_token}"},
        {"Content-Type", "application/json"}
      ])
      |> parse_response()

    case resp do
      {:ok, %{results: results, next: next}} ->
        deals_acc = deals_acc ++ results

        if next === nil do
          {:ok, deals_acc}
        else
          fetch_year_deals(next, deals_acc)
        end

      {error_code, error_message} ->
        {error_code, "[Hubspot] " <> error_message}
    end
  end

  @type deal :: %{id: String.t()}

  @type deals_response_success :: {:ok, %{results: list(deal), next: String.t() | nil}}
  @type deals_response_failure ::
          {:bad_request, String.t()}
          | {:unauthorized, String.t()}
          | {:internal_server_error, String.t()}

  @spec parse_response({:ok, map()}) :: deals_response_success()
  defp parse_response({:ok, %{body: body, status: 200}}) do
    decoded = Jason.decode!(body)
    results = decoded["results"]
    Logger.info("[Hubspot] #{length(results)} in request")
    {:ok, %{results: results, next: decoded["paging"]["next"]["after"]}}
  end

  @spec parse_response({:ok, map()}) :: deals_response_failure()
  defp parse_response({:ok, %{body: body, status: 400}}) do
    decoded = Jason.decode!(body)
    {:bad_request, decoded["message"]}
  end

  @spec parse_response({:ok, map()}) :: deals_response_failure()
  defp parse_response({:ok, %{body: body, status: 401}}) do
    decoded = Jason.decode!(body)
    {:unauthorized, decoded["message"]}
  end

  @spec parse_response({:ok, map()}) :: deals_response_failure()
  defp parse_response({:ok, %{body: body, status: 500}}) do
    decoded = Jason.decode!(body)
    {:internal_server_error, decoded["message"]}
  end

  @spec parse_response({:ok, map()}) :: deals_response_failure()
  defp parse_response({:ok, %{body: body, status: _}}) do
    decoded = Jason.decode!(body)
    {:internal_server_error, decoded["message"]}
  end

  @spec parse_response({:error, Exception.t()}) :: deals_response_failure()
  defp parse_response({:error, error}) do
    {:internal_server_error, error.message}
  end
end
