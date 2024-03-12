defmodule FruitPicker.Repo.Migrations.AddCommPrefsToPerson do
  use Ecto.Migration

  def change do
    alter table(:people) do
      add(:accepts_portal_communications, :boolean, default: false)
    end
  end
end
