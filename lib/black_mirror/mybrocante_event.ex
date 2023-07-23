defmodule BlackMirror.MyBrocanteEvent do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset
  alias BlackMirror.Repo
  alias __MODULE__

  schema "mybrocante_events" do
    field(:customer_id, :integer)
    field(:amount, :integer)
    field(:date, :utc_datetime)
  end

  def get_all_events() do
    MyBrocanteEvent |> Repo.all()
  end

  def create_event(attrs \\ %{}) do
    %MyBrocanteEvent{}
    |> MyBrocanteEvent.changeset(attrs)
    |> Repo.insert()
  end

  def changeset(%MyBrocanteEvent{} = event, attrs) do
    event
    |> cast(attrs, [:customer_id, :amount])
    |> cast_date(attrs)
    |> validate_required([:customer_id, :amount, :date])
  end

  def cast_date(%Ecto.Changeset{} = changeset, attrs) do
    case Map.get(attrs, "date") do
      nil ->
        add_error(changeset, :date, "can't be nil")

      date_str ->
        case Integer.parse(date_str) do
          {timestamp, _} ->
            case DateTime.from_unix(timestamp, :millisecond) do
              {:ok, datetime} ->
                change(changeset, %{date: datetime |> DateTime.truncate(:second)})

              {:error, err} ->
                add_error(changeset, :date, "could not convert timestamp to datetime: #{err}")
            end

          _ ->
            add_error(changeset, :date, "could not convert timestamp to integer")
        end
    end
  end
end
