defmodule BlackMirrorWeb.HomeLive do
  alias BlackMirror.Repo
  alias BlackMirror.Message
  alias BlackMirror.Sound
  use BlackMirrorWeb, :live_view
  require WeatherComponent
  require Logger

  @clock_update_interval 1000
  # refresh weather every hour
  @weather_update_interval 1000 * 3600
  # refresh display (data/messages) every 3 seconds
  @display_update_interval 1000 * 3
  @timezone "Europe/Paris"

  @type display :: :data | :message

  @impl true
  def mount(_params, _session, socket) do
    start_tick()

    socket =
      socket
      |> update_date_and_time()
      |> update_weather()
      |> init_mybrocante()
      |> init_messages()
      |> assign(current_display: :data)
      |> assign(current_message_idx: 0)

    if connected?(socket) do
      Message.subscribe()
      Sound.subscribe()
    end

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

  @impl true
  def handle_info(:update_display, socket) do
    schedule_display_update()

    case socket.assigns.current_display do
      :data ->
        {:noreply, assign(socket, current_display: :message, current_message_idx: 0)}

      :message ->
        if socket.assigns.current_message_idx == length(socket.assigns.messages) - 1 do
          {:noreply, assign(socket, current_display: :data)}
        else
          {:noreply, assign(socket, current_message_idx: socket.assigns.current_message_idx + 1)}
        end
    end
  end

  def handle_info({BlackMirror.Message, [:message, :added], new_message}, socket) do
    {:noreply,
     socket
     |> assign(messages: socket.assigns.messages ++ [new_message])}
  end

  def handle_info({BlackMirror.Message, [:message, :deleted], deleted_message_id}, socket) do
    {:noreply,
     socket
     |> assign(
       messages:
         socket.assigns.messages
         |> Enum.filter(fn m -> m.id != deleted_message_id end)
     )}
  end

  def handle_info({BlackMirror.Sound, :trigger_sound, sound_url}, socket) do
    {:noreply, push_event(socket, "trigger_sound", %{url: sound_url})}
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

  defp init_messages(socket) do
    messages = Repo.all(BlackMirror.Message)

    if length(messages) > 0 do
      schedule_display_update()
    end

    assign(socket, messages: messages)
  end

  defp schedule_display_update do
    Process.send_after(self(), :update_display, @display_update_interval)
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
    <div class="bg-black antialiased text-white px-4 py-20 h-screen overflow-hidden">
      <div class="space-y-8 mx-auto max-w-3xl h-full flex flex-col">
        <div class="columns-2">
          <div>
            <div class="text-5xl font-bold"><%= String.capitalize(@current_day) %></div>
            <div class="text-3xl mt-2"><%= @current_date %></div>
          </div>
          <div class="text-right">
            <div class="text-8xl"><%= @current_time %></div>
            <.live_component module={WeatherComponent} id="weather" , weather={@weather} />
          </div>
        </div>

        <%= case @current_display do %>
          <% :data -> %>
            <div class="grid grid-cols-7 text-gray-500 font-bold text-3xl">
              <div class="col-span-4">MOIS EN COURS</div>
              <div class="col-span-1 w-0.5 self-stretch bg-white bg-opacity-70"></div>
              <div class="col-span-2">ANNUEL</div>
            </div>

            <.live_component module={MyBrocanteComponent} id="mybrocante" , mybrocante={@mybrocante} />
          <% :message -> %>
            <% message = Enum.at(@messages, @current_message_idx) %>
            <div
              class="flex items-center justify-center w-full flex-grow flex-col slide-in message-box"
              phx-hook="MessageSlide"
              id={"message#{@current_message_idx}"}
              data-index={@current_message_idx}
            >
              <div class={(if String.length(message.content) > 20, do: "text-4xl", else: "text-5xl") <> " pb-8 text-center"}>
                <%= message.content %>
              </div>
              <%= if message.image do %>
                <div>
                  <img alt="image" width="400" height="400" src={message.image} />
                </div>
              <% end %>
            </div>
        <% end %>
      </div>
    </div>
    """
  end
end
