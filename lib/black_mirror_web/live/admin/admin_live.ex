defmodule BlackMirrorWeb.AdminLive do
  alias BlackMirrorWeb.Admin.SoundsComponent
  use BlackMirrorWeb, :live_view
  alias BlackMirror.Repo
  alias BlackMirrorWeb.Admin.MessagesComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(messages: Repo.all(BlackMirror.Message))
     |> assign(sounds: Repo.all(BlackMirror.Sound))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-10 py-10 bg-gray-100 h-screen space-y-5">
      <h1 class="text-2xl font-bold">Blackmirror Admin</h1>

      <div class="flex flex-row space-x-8">
        <div class="basis-1/2">
          <.live_component module={MessagesComponent} id="messages-card" messages={@messages} />
        </div>
        <div class="basis-1/2">
          <.live_component module={SoundsComponent} id="sounds-card" sounds={@sounds} />
        </div>
      </div>
    </div>
    """
  end

  def handle_info({:put_flash, type, message}, _params, socket) do
    {:noreply, put_flash(socket, type, message)}
  end
end
