defmodule BlackMirror.Sound do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phoenix.PubSub
  alias __MODULE__

  @topic inspect(__MODULE__)

  schema "sounds" do
    field(:url, :string)
  end

  def changeset(sound \\ %Sound{}, attrs) do
    sound
    |> cast(attrs, [:url])
    |> validate_required([:url])
    |> validate_format(:url, ~r/\.wav|\.mp3|\.ogg$/)
  end

  def subscribe do
    PubSub.subscribe(BlackMirror.PubSub, @topic)
  end

  def notify_subscribers({:trigger, sound_url}) do
    PubSub.broadcast(BlackMirror.PubSub, @topic, {__MODULE__, :trigger_sound, sound_url})
    {:ok, nil}
  end
end
