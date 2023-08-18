defmodule WeatherComponent do
  use Phoenix.LiveComponent
  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="text-4xl font-bold"><%= @weather %>°</div>

    </div>
    """
  end
end
