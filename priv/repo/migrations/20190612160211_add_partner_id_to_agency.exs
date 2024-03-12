defmodule FruitPicker.Repo.Migrations.AddPartnerIdToAgency do
  use Ecto.Migration

  def change do
    alter table(:agencies) do
      add(:partner_id, references(:people))
    end
  end
end
