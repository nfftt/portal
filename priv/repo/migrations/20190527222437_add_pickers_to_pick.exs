defmodule FruitPicker.Repo.Migrations.AddPickersToPick do
  use Ecto.Migration

  def change do
    create table(:picks_people) do
      add(:pick_id, references(:picks), null: false)
      add(:person_id, references(:people), null: false)

      timestamps()
    end
  end
end
