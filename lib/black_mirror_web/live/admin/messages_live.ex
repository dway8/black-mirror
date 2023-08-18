defmodule BlackMirrorWeb.Admin.MessagesComponent do
  use Phoenix.LiveComponent

  use Phoenix.VerifiedRoutes,
    endpoint: BlackMirrorWeb.Endpoint,
    router: BlackMirrorWeb.Router,
    statics: BlackMirrorWeb.static_paths()

  import BlackMirrorWeb.CardComponent
  import BlackMirrorWeb.CoreComponents
  import BlackMirrorWeb.Common
  alias BlackMirror.Message
  alias BlackMirror.Repo

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(messages: assigns.messages)
     |> assign(show_message_modal: false)
     |> assign(new_message_form: to_form(BlackMirror.Message.create_changeset(%{content: ""})))
     |> assign(:uploaded_files, [])
     |> allow_upload(:message_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.card>
        <h2 class="text-lg font-bold mb-5">Messages</h2>
        <table class="table-auto mb-5 w-full">
          <thead>
            <tr>
              <th class="border-b p-2 text-left font-semibold">Message</th>
              <th class="border-b p-2 text-left font-semibold">Image</th>
              <th class="border-b p-2 text-left font-semibold">Date d'ajout</th>
              <th class="pl-3"></th>
            </tr>
          </thead>
          <tbody>
            <%= for message <- @messages do %>
              <tr id={"message-#{message.id}"} phx-remove={fade_out()}>
                <td class="w-2/5 border-b p-2 text-slate-400" style="white-space: pre-wrap;">
                  <%= message.content %>
                </td>
                <td class="border-b p-2">
                  <%= if message.image do %>
                    <img alt="image" width="200" height="200" src={message.image} />
                  <% end %>
                </td>
                <td class="border-b p-2 text-slate-400 text-xs">
                  <%= Timex.format!(message.inserted_at, "{WDfull} {D} {Mfull} {h24}:{m}") %>
                </td>

                <td class="pl-3 text-center">
                  <button
                    phx-click="delete_message"
                    phx-value-id={message.id}
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
        <.button phx-click={show_modal("message_modal")} class="bg-blue-600 hover:bg-blue-700">
          Ajouter un message
        </.button>
      </.card>

      <.modal id="message_modal" show={@show_message_modal}>
        <div class="space-y-4">
          <.simple_form
            for={@new_message_form}
            phx-submit="save_new_message"
            phx-change="validate"
            phx-target={@myself}
          >
            <.input
              type="textarea"
              id="message-input"
              field={@new_message_form[:content]}
              label="Nouveau message"
            />
            <div class="file-container" phx-drop-target={@uploads.message_image.ref}>
              <label for={@uploads.message_image.ref} class="font-semibold">Image</label>
              <.live_file_input upload={@uploads.message_image} />

              <%= for entry <- @uploads.message_image.entries do %>
                <.live_img_preview entry={entry} width="100" />
                <button phx-click="cancel-upload" phx-value-ref={entry.ref}>&times;</button>
              <% end %>
            </div>
            <div class="relative">
              <div class="absolute right-0">
                <.button phx-click={hide_modal("message_modal")} class="bg-gray-400 hover:bg-gray-500">
                  Annuler
                </.button>
                <.button class="bg-blue-600 hover:bg-blue-700" type="submit">Confirmer</.button>
              </div>
            </div>
          </.simple_form>
        </div>
      </.modal>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"message" => params}, socket) do
    params = Map.put(params, "image", "")

    form =
      %Message{}
      |> Message.create_changeset(params)
      |> to_form()

    {:noreply, assign(socket, new_message_form: form)}
  end

  @impl true
  def handle_event("save_new_message", %{"message" => params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :message_image, fn %{path: path}, _entry ->
        dest =
          Path.join([:code.priv_dir(:black_mirror), "static", "uploads", Path.basename(path)])

        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    params = Map.put(params, "image", Enum.at(uploaded_files, 0))

    case Repo.insert(BlackMirror.Message.create_changeset(params)) do
      {:error, changeset} ->
        {:noreply, socket |> put_flash(:error, inspect(changeset))}

      {:ok, _} ->
        {:noreply,
         socket
         |> assign(messages: Repo.all(BlackMirror.Message))
         |> push_event("close_modal", %{to: "#close_modal_btn_message_modal"})
         |> put_flash(:info, "Message enregistré")}
    end
  end

  @impl true
  def handle_event("delete_message", params, socket) do
    case BlackMirror.Message.delete_by_id(Map.get(params, "id")) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(messages: Repo.all(BlackMirror.Message))
         |> put_flash(:info, "Message supprimé")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Le message n'a pas pu être supprimé")}
    end
  end
end
