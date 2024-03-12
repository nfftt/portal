defmodule FruitPicker.Repo.Migrations.UpdateInstructionsEquipmentSets do
  use Ecto.Migration

  def up do
    rename table("equipment_sets"), :special_instructions, to: :access_instructions

    alter table(:equipment_sets) do
      add(:secondary_contact_name, :string)
      add(:bike_lock_instructions, :text)
    end
  end

  def down do
    rename table("equipment_sets"), :access_instructions, to: :special_instructions

    alter table(:equipment_sets) do
      remove(:secondary_contact_name)
      remove(:bike_lock_instructions)
    end
  end
end
