defmodule BlackMirrorWeb.AdminLive do
  use BlackMirrorWeb, :live_view
  alias BlackMirror.Repo
  alias BlackMirrorWeb.Admin.MessagesComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(messages: Repo.all(BlackMirror.Message))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-10 py-10 bg-gray-100 h-screen space-y-5">
      <h1 class="text-2xl font-bold">Blackmirror Admin</h1>

      <div class="max-w-3xl">
        <.live_component module={MessagesComponent} id="messages-component" messages={@messages} />
      </div>
    </div>
    """
  end
end
