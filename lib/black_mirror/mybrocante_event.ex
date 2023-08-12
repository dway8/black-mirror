defmodule BlackMirror.MyBrocanteEvent do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
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

  def refresh_year_events(params) do
    now = DateTime.utc_now()
    current_year = now.year

    # delete year events
    from(e in MyBrocanteEvent,
      where: fragment("date_part('year', ?)", e.date) == ^current_year
    )
    |> Repo.delete_all()

    IO.inspect(params)

    # insert all
    Repo.transaction(fn ->
      params
      |> Enum.each(&create_event(&1))
    end)
  end

  defp cast_date(%Ecto.Changeset{} = changeset, attrs) do
    case Map.get(attrs, "date") do
      nil ->
        add_error(changeset, :date, "can't be nil")

      timestamp ->
        case DateTime.from_unix(timestamp, :millisecond) do
          {:ok, datetime} ->
            change(changeset, %{date: datetime |> DateTime.truncate(:second)})

          {:error, err} ->
            add_error(changeset, :date, "could not convert timestamp to datetime: #{err}")
        end
    end
  end
end
