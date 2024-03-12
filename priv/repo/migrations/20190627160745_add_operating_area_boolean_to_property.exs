defmodule FruitPicker.Repo.Migrations.AddOperatingAreaBooleanToProperty do
  use Ecto.Migration

  def up do
    alter table(:properties) do
      add(:is_in_operating_area, :boolean, default: true)
    end
  end

  def down do
    alter table(:properties) do
      remove(:is_in_operating_area)
    end
  end
end
