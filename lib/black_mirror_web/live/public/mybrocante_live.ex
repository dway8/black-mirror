defmodule MyBrocanteComponent do
  use BlackMirrorWeb, :live_component
  require Logger
  alias BlackMirror.Cldr

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-5">
      <img src="images/mybrocante-logo.png" width="220px" />

      <div class="grid grid-cols-7 text-3xl">
        <div class="col-span-4 space-y-3">
          <div class="grid grid-cols-2">
            <div class="col-span-1 myb-red-color text-6xl font-bold">
              +<%= Cldr.Number.to_string!(@mybrocante.current_month_new_users) %>
            </div>
            <div class="col-span-1">
              <div class="font-bold"><%= Cldr.Number.to_string!(@mybrocante.total_users) %></div>
              <div class="text-gray-500">Clients</div>
            </div>
          </div>
          <div class="myb-blue-color text-6xl font-bold">
            <%= Cldr.Number.to_string!(div(@mybrocante.current_month_sales, 100), currency: "EUR") %>
          </div>
        </div>

        <div class="col-span-1 w-0.5 self-stretch bg-white bg-opacity-70"></div>

        <div class="col-span-2 space-y-3">
          <div>
            <div class="font-bold">
              <%= Cldr.Number.to_string!(div(@mybrocante.year_sales, 100), currency: "EUR") %>
            </div>
            <div class="text-gray-500">Cumul CA</div>
          </div>
          <div>
            <div class="font-bold">
              <%= Cldr.Number.to_string!(@mybrocante.sales_target_percent,
                format: :percent
              ) %>
            </div>
            <div class="text-gray-500">Objectif</div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
