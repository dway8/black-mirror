defmodule BlackMirror.Message do
  use Ecto.Schema
  alias Phoenix.PubSub
  alias BlackMirror.Repo
  import Ecto.Changeset
  alias __MODULE__

  @topic inspect(__MODULE__)

  schema "messages" do
    field(:content, :string)
    field(:image, :string)
    timestamps()
  end

  def create_changeset(changeset \\ %Message{}, attrs) do
    changeset
    |> cast(attrs, [:content, :image])
    |> validate_required([:content])
  end

  def delete_by_id(id) do
    message = Repo.get!(Message, id)
    Repo.delete(message)
  end

  def subscribe do
    PubSub.subscribe(BlackMirror.PubSub, @topic)
  end

  def notify_subscribers({:ok, result}, event) do
    PubSub.broadcast(BlackMirror.PubSub, @topic, {__MODULE__, event, result})
    {:ok, result}
  end
end
