defmodule FruitPicker.Repo.Migrations.ChangeLatlongToSeparateValues do
  use Ecto.Migration

  def up do
    alter table(:agencies) do
      remove(:latlong)
      add(:latitude, :float)
      add(:longitude, :float)
    end

    alter table(:properties) do
      remove(:latlong)
      add(:latitude, :float)
      add(:longitude, :float)
    end

    alter table(:equipment_sets) do
      remove(:latlong)
      add(:latitude, :float)
      add(:longitude, :float)
    end
  end

  def down do
    alter table(:agencies) do
      add(:latlong, :string)
      remove(:latitude)
      remove(:longitude)
    end

    alter table(:properties) do
      add(:latlong, :string)
      remove(:latitude)
      remove(:longitude)
    end

    alter table(:equipment_sets) do
      add(:latlong, :string)
      remove(:latitude)
      remove(:longitude)
    end
  end
end
