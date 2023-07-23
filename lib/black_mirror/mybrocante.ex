defmodule BlackMirror.MyBrocante do
  require Logger
  use Ecto.Schema
  alias BlackMirror.MyBrocante
  alias BlackMirror.MyBrocanteEvent
  alias BlackMirror.MyBrocanteSalesTarget

  defstruct [
    :current_month_new_users,
    :total_users,
    :current_month_sales,
    :year_sales,
    :sales_target_percent
  ]

  @type events :: [MyBrocanteEvent]
  @spec from_events(events) :: MyBrocante
  defp from_events(events) do
    total_users =
      events
      |> Enum.uniq_by(fn event -> event.customer_id end)
      |> length()

    now = DateTime.utc_now()
    current_year = now.year
    current_month = now.month

    current_year_events =
      events
      |> Enum.filter(fn event -> event.date.year == current_year end)

    current_month_events =
      events
      |> Enum.filter(fn event -> event.date.month == current_month end)

    current_month_new_users =
      current_month_events
      |> Enum.uniq_by(fn event -> event.customer_id end)
      |> length()

    current_month_sales =
      current_month_events
      |> Enum.reduce(0, fn e, acc -> e.amount + acc end)

    year_sales =
      current_year_events
      |> Enum.reduce(0, fn e, acc -> e.amount + acc end)

    year_target = MyBrocanteSalesTarget.get_current_year_sales_target()

    %MyBrocante{
      current_month_new_users: current_month_new_users,
      total_users: total_users,
      current_month_sales: current_month_sales,
      year_sales: year_sales,
      sales_target_percent: year_sales * 100 / year_target
    }
  end

  def fetch do
    MyBrocanteEvent.get_all_events()
    |> from_events()
  end
end
