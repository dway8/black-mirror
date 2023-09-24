defmodule WeatherComponent do
  use BlackMirrorWeb, :live_component
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
