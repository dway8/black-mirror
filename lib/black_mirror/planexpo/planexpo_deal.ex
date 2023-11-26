defmodule BlackMirror.PlanexpoDeal do
  require Logger
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias BlackMirror.Repo
  alias Phoenix.PubSub
  alias __MODULE__

  @topic inspect(__MODULE__)

  schema "planexpo_deals" do
    field(:amount, :integer)
    field(:date, :utc_datetime)
    field(:kind, Ecto.Enum, values: [:new_client, :renewal, :upsell])
  end

  def get_all_deals() do
    PlanexpoDeal |> Repo.all()
  end

  def create_deal(attrs \\ %{}) do
    %PlanexpoDeal{}
    |> PlanexpoDeal.changeset(attrs)
    |> Repo.insert()
  end

  def changeset(%PlanexpoDeal{} = deal, attrs) do
    deal
    |> cast(attrs, [:amount, :kind])
    |> cast_date(attrs)
    |> validate_required([:amount, :date, :kind])
  end

  def refresh_year_deals(params) do
    now = DateTime.utc_now()
    current_year = now.year

    # delete year deals
    from(d in PlanexpoDeal,
      where: fragment("date_part('year', ?)", d.date) == ^current_year
    )
    |> Repo.delete_all()

    IO.inspect(params)

    # insert all
    Repo.transaction(fn ->
      params
      |> Enum.each(&create_deal(&1))
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

  def subscribe do
    PubSub.subscribe(BlackMirror.PubSub, @topic)
  end

  def notify_subscribers(:events_updated) do
    PubSub.broadcast(BlackMirror.PubSub, @topic, {__MODULE__, :deals_updated})
    {:ok}
  end
end
