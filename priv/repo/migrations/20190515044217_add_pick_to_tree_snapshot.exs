defmodule FruitPicker.Repo.Migrations.AddPickToTreeSnapshot do
  use Ecto.Migration

  def change do
    alter table(:tree_snapshots) do
      add(:pick_id, references(:picks))
    end
  end
end
