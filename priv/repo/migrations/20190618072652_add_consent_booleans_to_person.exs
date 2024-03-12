defmodule FruitPicker.Repo.Migrations.AddConsentBooleansToPerson do
  use Ecto.Migration

  def up do
    alter table(:people) do
      add(:accepts_consent_picker, :boolean, default: true)
      add(:accepts_consent_tree_owner, :boolean, default: true)
    end
  end

  def down do
    alter table(:people) do
      remove(:accepts_consent_picker)
      remove(:accepts_consent_tree_owner)
    end
  end
end
