defmodule BlackMirror.Sound do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "sounds" do
    field(:url, :string)
  end

  def changeset(sound \\ %Sound{}, attrs) do
    sound
    |> cast(attrs, [:url])
    |> validate_required([:url])
    |> validate_format(:url, ~r/\.wav|\.mp3|\.ogg$/)
  end
end
