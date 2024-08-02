defmodule FruitPicker.Repo.Migrations.AddDeletedToProperties do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add(:deleted, :boolean, default: false)
    end
  end
end
