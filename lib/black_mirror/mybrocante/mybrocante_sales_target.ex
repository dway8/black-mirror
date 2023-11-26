defmodule BlackMirror.MyBrocanteSalesTarget do
  require Logger
  use Ecto.Schema
  alias BlackMirror.Repo
  alias __MODULE__

  schema "mybrocante_sales_targets" do
    field(:year, :integer)
    field(:amount, :integer)
  end

  def get_current_year_sales_target() do
    target = MyBrocanteSalesTarget |> Repo.one(year: DateTime.utc_now().year)

    if target do
      target |> Map.get(:amount)
    else
      0
    end
  end
end
