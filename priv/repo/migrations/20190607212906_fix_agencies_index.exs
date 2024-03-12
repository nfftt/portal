defmodule FruitPicker.Repo.Migrations.FixAgenciesIndex do
  use Ecto.Migration

  def up do
    drop index(:agencies, [:name], unique: true)
    create index(:agencies, [:name])
  end

  def down do
    drop index(:agencies, [:name])
    create index(:agencies, [:name], unique: true)
  end
end
