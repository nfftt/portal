defmodule FruitPicker.Repo.Migrations.AddMapUpdatedTimestamp do
  use Ecto.Migration

  def change do
    alter table(:agencies) do
      add(:coordinates_updated_at, :naive_datetime_usec)
    end

    alter table(:properties) do
      add(:coordinates_updated_at, :naive_datetime_usec)
    end

    alter table(:equipment_sets) do
      add(:coordinates_updated_at, :naive_datetime_usec)
    end
  end
end
