defmodule BlackMirror.Repo.Migrations.AddPlanexpoDealsTable do
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE deal_kind AS ENUM ('new_client', 'renewal', 'upsell')"
    drop_query = "DROP TYPE deal_kind"
    execute(create_query, drop_query)

    create table("planexpo_deals") do
      add(:amount, :integer)
      add(:date, :utc_datetime)
      add(:kind, :deal_kind)
    end
  end
end
