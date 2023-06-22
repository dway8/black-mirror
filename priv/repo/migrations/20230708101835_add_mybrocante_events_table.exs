defmodule BlackMirror.Repo.Migrations.AddMybrocanteEventsTable do
  use Ecto.Migration

  def change do
    create table("mybrocante_events") do
      add(:customer_id, :integer)
      add(:amount, :integer)
      add(:date, :utc_datetime)
    end
  end
end
