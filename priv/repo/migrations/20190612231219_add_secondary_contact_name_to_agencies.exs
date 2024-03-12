defmodule FruitPicker.Repo.Migrations.AddSecondaryContactNameToAgencies do
  use Ecto.Migration

  def change do
    alter table(:agencies) do
      add(:secondary_contact_name, :string)
    end
  end
end
