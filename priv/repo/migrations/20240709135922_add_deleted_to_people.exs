defmodule FruitPicker.Repo.Migrations.AddDeletedToPeople do
  use Ecto.Migration

  def change do
    alter table(:people) do
      add(:deleted, :boolean, default: false)
    end
  end
end
