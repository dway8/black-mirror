defmodule BlackMirrorWeb.Admin.SoundsComponent do
  use BlackMirrorWeb, :live_component
  import BlackMirrorWeb.CardComponent
  import BlackMirrorWeb.CoreComponents
  import BlackMirrorWeb.Common
  alias BlackMirror.Repo
  alias BlackMirror.Sound

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(sounds: assigns.sounds)
     |> assign(show_form: false)
     |> assign(form: to_form(BlackMirror.Sound.changeset(%Sound{}, %{})))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.card>
        <h2 class="text-lg font-bold mb-5">Sons</h2>
        <table class="table-auto mb-5 w-full">
          <thead>
            <tr>
              <th class="border-b p-2 text-left font-semibold">URL</th>
              <th class="border-b p-2 text-left font-semibold"></th>
              <th class="border-b p-2 text-left font-semibold"></th>
              <th class="pl-3"></th>
            </tr>
          </thead>
          <tbody>
            <%= for sound <- @sounds do %>
              <tr id={"sound-#{sound.id}"} phx-remove={fade_out()}>
                <td
                  class="w-2/5 border-b p-2 text-slate-400 text-sm break-all"
                  style="min-width: 200px;"
                >
                  <%= sound.url %>
                </td>
                <td class="border-b p-2 w-32">
                  <audio controls src={sound.url} class="w-60 h-9" />
                </td>
                <td class="border-b p-2 text-slate-400">
                  <.small_button
                    phx-click="trigger_sound"
                    phx-value-sound_url={sound.url}
                    phx-target={@myself}
                  >
                    Déclencher
                  </.small_button>
                </td>

                <td class="pl-3 text-center">
                  <button
                    phx-click="delete_sound"
                    phx-value-id={sound.id}
                    phx-target={@myself}
                    class="inline-flex p-1 w-8 h-8 items-center justify-center hover:rounded-full hover:bg-red-600 hover:bg-opacity-10"
                  >
                    <.icon name="hero-trash" class=" text-red-600 w-5 h-5" />
                  </button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
        <%= if assigns.show_form do
          render_add_sound(assigns)
        else
          add_sound_button(assigns)
        end %>
      </.card>
    </div>
    """
  end

  def add_sound_button(assigns) do
    ~H"""
    <.button phx-click="show_form" phx-target={@myself} class="bg-blue-600 hover:bg-blue-700">
      Ajouter un son
    </.button>
    """
  end

  def render_add_sound(assigns) do
    ~H"""
    <.simple_form for={@form} phx-submit="save_new_sound" phx-target={@myself}>
      <div class="flex items-center w-full space-x-2">
        <div class="relative w-full">
          <.input field={@form[:url]} type="text" placeholder="URL" class="w-full" />
        </div>
        <.button
          type="button"
          phx-click="hide_form"
          phx-target={@myself}
          class="bg-gray-400 hover:bg-gray-500"
        >
          Annuler
        </.button>
        <.button class="bg-blue-600 hover:bg-blue-700" type="submit">Confirmer</.button>
      </div>
    </.simple_form>
    """
  end

  @impl true
  def handle_event("show_form", _params, socket) do
    {:noreply, socket |> assign(show_form: true)}
  end

  @impl true
  def handle_event("hide_form", _params, socket) do
    {:noreply, socket |> assign(show_form: false)}
  end

  @impl true
  def handle_event("save_new_sound", %{"sound" => params}, socket) do
    case Repo.insert(BlackMirror.Sound.changeset(params)) do
      {:error, _} ->
        {:noreply,
         socket |> put_flash!(:error, "URL invalide. Formats acceptés : .mp3, .wav, .ogg")}

      {:ok, _} ->
        {:noreply,
         socket
         |> assign(sounds: Repo.all(BlackMirror.Sound))
         |> assign(show_form: false)
         |> put_flash!(:info, "Son enregistré")}
    end
  end

  @impl true
  def handle_event("delete_sound", params, socket) do
    sound = Repo.get!(Sound, Map.get(params, "id"))

    case Repo.delete(sound) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(sounds: Repo.all(BlackMirror.Sound))
         |> put_flash!(:info, "Son supprimé")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash!(:error, "Le son n'a pas pu être supprimé")}
    end
  end

  @impl true
  def handle_event("trigger_sound", params, socket) do
    BlackMirror.Sound.notify_subscribers({:trigger, Map.get(params, "sound_url")})

    {:noreply, socket}
  end
end
