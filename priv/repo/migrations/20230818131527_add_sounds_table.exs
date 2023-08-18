defmodule BlackMirror.Repo.Migrations.AddSoundsTable do
  use Ecto.Migration

  def change do
    create table("sounds") do
      add(:url, :string)
    end
  end
end
