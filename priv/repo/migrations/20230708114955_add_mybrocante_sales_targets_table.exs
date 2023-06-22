defmodule BlackMirror.Repo.Migrations.AddMybrocanteSalesTargetTable do
  use Ecto.Migration

  def change do
    create table("mybrocante_sales_targets") do
      add(:year, :integer)
      add(:amount, :integer)
    end
  end
end
