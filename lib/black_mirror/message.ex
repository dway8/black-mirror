defmodule BlackMirror.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "messages" do
    field(:content, :string)
    timestamps()
  end

  def create_changeset(changeset \\ %Message{}, attrs) do
    changeset
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end
