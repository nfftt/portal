defmodule FruitPicker.Repo.Migrations.AddPersonTypes do
  use Ecto.Migration

  def up do
    alter table(:people) do
      add(:is_picker, :boolean, default: false)
      add(:is_lead_picker, :boolean, default: false)
      add(:is_tree_owner, :boolean, default: false)
    end
  end

  def down do
    alter table(:people) do
      remove(:is_picker)
      remove(:is_lead_picker)
      remove(:is_tree_owner)
    end
  end
end
