defmodule BlackMirror.MyBrocanteEvent do
  require Logger
  use Ecto.Schema
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
end
