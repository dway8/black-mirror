defmodule BlackMirrorWeb.MyBrocanteAPIController do
  alias BlackMirror.MyBrocanteEvent
  use BlackMirrorWeb, :controller

  def new(conn, params) do
    IO.puts("new")

    case MyBrocanteEvent.create_event(params) do
      {:ok, %MyBrocanteEvent{} = _event} ->
        BlackMirror.MyBrocanteEvent.notify_subscribers(:events_updated)
        send_resp(conn, :ok, "")

      {:error, changeset} ->
        error = changeset_error_to_string(changeset)

        IO.puts(
          "[MyBrocante API] Error when creating new event:\n#{error}. Params received were:"
        )

        IO.inspect(params)

        send_resp(conn, :bad_request, error)
    end
  end

  def refresh(conn, params) do
    IO.puts("refresh")

    events_list = Map.get(params, "events")

    case MyBrocanteEvent.refresh_year_events(events_list) do
      {:ok, _} ->
        BlackMirror.MyBrocanteEvent.notify_subscribers(:events_updated)
        send_resp(conn, :ok, "")

      {:error, _} ->
        IO.puts(
          "[MyBrocante API] No events were created when refreshing year events. Params received were:"
        )

        IO.inspect(params)

        send_resp(conn, :bad_request, "")
    end
  end

  def changeset_error_to_string(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.reduce("", fn {k, v}, acc ->
      joined_errors = Enum.join(v, "; ")
      "#{acc}#{k}: #{joined_errors}\n"
    end)
  end
end
