defmodule BlackMirror.Message do
  use Ecto.Schema
  alias BlackMirror.Repo
  import Ecto.Changeset
  alias __MODULE__

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
end
