defmodule FruitPicker.Repo.Migrations.AddEquipmentSets do
  use Ecto.Migration

  def change do
    create table(:equipment_sets) do
      add(:name, :string)
      add(:address, :string)
      add(:closest_intersection, :string)
      add(:latlong, :string)
      add(:contact_name, :string)
      add(:contact_number, :string)
      add(:secondary_contact_number, :string)
      add(:special_instructions, :text)
      add(:is_active, :boolean, default: true)

      timestamps()
    end

    create unique_index(:equipment_sets, [:name])
  end
end
