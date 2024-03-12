defmodule FruitPicker.Repo.Migrations.AddContactEmailsToAgencies do
  use Ecto.Migration

  def change do
    alter table(:agencies) do
      add(:contact_email, :string)
      add(:secondary_contact_email, :string)
    end
  end
end
