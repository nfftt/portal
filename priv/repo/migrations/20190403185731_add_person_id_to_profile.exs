defmodule FruitPicker.Repo.Migrations.AddPersonIdToProfile do
  use Ecto.Migration

  def change do
    alter table(:profiles) do
      add(:person_id, references(:people))
    end
  end
end
