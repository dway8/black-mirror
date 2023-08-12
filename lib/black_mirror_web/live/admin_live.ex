defmodule BlackMirrorWeb.AdminLive do
  use BlackMirrorWeb, :live_view
  alias BlackMirror.Message
  alias BlackMirror.Repo
  import BlackMirrorWeb.CardComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(show_message_modal: false)
     |> assign(messages: Repo.all(BlackMirror.Message))
     |> assign(new_message_form: to_form(BlackMirror.Message.create_changeset(%{content: ""})))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-10 py-10 bg-gray-100 h-screen space-y-5">
        <h1 class="text-2xl font-bold">Blackmirror Admin</h1>

        <div class="max-w-3xl">
        <.card>
          <h2 class="text-lg font-bold mb-5">Messages</h2>
          <table class="table-auto mb-5">
            <thead>
              <tr>
                <th class="border-b p-2 text-left font-semibold">Message</th>
                <th class="border-b p-2 text-left font-semibold">Date d'ajout</th>
              </tr>
            </thead>
            <tbody>
              <%= for message <- @messages do %>
                <tr>
                  <td class="border-b p-2 text-slate-400" style="white-space: pre-wrap;"><%= message.content %></td>
                  <td class="border-b p-2 text-slate-400 text-xs"><%= Timex.format!(message.inserted_at, "{WDfull} {D} {Mfull} {h24}:{m}") %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
          <.button phx-click={show_modal("message_modal")} class="bg-blue-600 hover:bg-blue-700">
            Ajouter un message
          </.button>
        </.card>
    </div>

        <.modal id="message_modal" show={@show_message_modal}>
          <.simple_form for={@new_message_form} phx-submit="save_new_message">
            <.input
              type="textarea"
              id="message-input"
              field={@new_message_form[:content]}
              label="Nouveau message"
            />
            <actions>
              <div class="relative">
                <div class="absolute right-0">
                  <.button
                    phx-click={hide_modal("message_modal")}
                    class="bg-gray-400 hover:bg-gray-500"
                  >
                    Annuler
                  </.button>
                  <.button class="bg-blue-600 hover:bg-blue-700" type="submit">Confirmer</.button>
                </div>
              </div>
            </actions>
          </.simple_form>
        </.modal>
    </div>
    """
  end

  @impl true
  def handle_event("save_new_message", %{"message" => params}, socket) do
    case Repo.insert(BlackMirror.Message.create_changeset(params)) do
      {:error, message} ->
        {:noreply, socket |> put_flash(:error, inspect(message))}

      {:ok, _} ->
        {:noreply,
         socket
         |> assign(messages: Repo.all(BlackMirror.Message))
         |> push_event("close_modal", %{to: "#close_modal_btn_message_modal"})}
    end
  end
end
