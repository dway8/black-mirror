defmodule BlackMirrorWeb.HomeLive do
  use BlackMirrorWeb, :live_view
  require WeatherComponent
  require Logger

  @clock_update_interval 1000
  # refresh weather every hour
  @weather_update_interval 1000 * 3600
  @timezone "Europe/Paris"

  def mount(_params, _session, socket) do
    start_tick()

    socket =
      socket
      |> update_date_and_time()
      |> update_weather()
      |> init_mybrocante()

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    start_tick()
    {:noreply, update_date_and_time(socket)}
  end

  @impl true
  def handle_info(:update_weather, socket) do
    schedule_weather_update()
    {:noreply, update_weather(socket)}
  end

  defp update_date_and_time(socket) do
    current = Timex.now(@timezone)

    assign(
      socket,
      current_day: "#{Timex.format!(current, "{WDfull}")}",
      current_date: "#{Timex.format!(current, "{D} {Mfull}")}",
      current_time: "#{Timex.format!(current, "{h24}:{m}")}"
    )
  end

  defp update_weather(socket) do
    forecast = BlackMirror.Forecast.fetch()
    assign(socket, weather: forecast)
  end

  defp init_mybrocante(socket) do
    mybrocante = BlackMirror.MyBrocante.fetch()
    assign(socket, mybrocante: mybrocante)
  end

  def start_tick do
    Process.send_after(self(), :tick, @clock_update_interval)
  end

  def schedule_weather_update do
    Process.send_after(self(), :update_weather, @weather_update_interval)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8">

      <div class="columns-2">
        <div>
          <div class="text-5xl font-bold"><%= String.capitalize(@current_day) %></div>
          <div class="text-3xl mt-2"><%= @current_date %></div>
        </div>
        <div class="text-right">
          <div class="text-8xl"><%= @current_time %></div>
          <.live_component module={WeatherComponent} id="weather", weather= {@weather} />
        </div>
      </div>

      <div class="grid grid-cols-7 text-gray-500 font-bold text-3xl">
        <div class="col-span-4">MOIS EN COURS</div>
        <div class="col-span-1 w-0.5 self-stretch bg-white bg-opacity-70"></div>
        <div class="col-span-2">ANNUEL</div>
      </div>

      <.live_component module={MyBrocanteComponent} id="mybrocante", mybrocante= {@mybrocante} />



    </div>

    """
  end
end
