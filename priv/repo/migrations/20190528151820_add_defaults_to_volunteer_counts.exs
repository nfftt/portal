defmodule FruitPicker.Repo.Migrations.AddDefaultsToVolunteerCounts do
  use Ecto.Migration

  def change do
    alter table(:picks) do
      modify(:volunteers_min, :integer, default: 2)
      modify(:volunteers_max, :integer, default: 5)
    end
  end
end
