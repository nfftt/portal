defmodule FruitPicker.Repo.Migrations.CreatePickReportWithAgencies do
  use Ecto.Migration

  def change do
    create table(:pick_fruit_agencies) do
      add :pounds_donated, :float, null: false

      add :pick_fruit_id, references(:pick_fruit), null: false
      add :agency_id, references(:agencies), null: false

      timestamps()
    end

    create index(:pick_fruit_agencies, [:pick_fruit_id])
  end
end
