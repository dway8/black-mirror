defmodule BlackMirror.Repo.Migrations.AddMessageImage do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add(:image, :string)
    end
  end
end
