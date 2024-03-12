defmodule FruitPicker.Repo.Migrations.AddProfiles do
  use Ecto.Migration
  alias FruitPicker.Accounts.Profile.ProvinceEnum

  def up do
    ProvinceEnum.create_type()
    create table(:profiles) do
      add(:phone_number, :string)
      add(:secondary_phone_number, :string)
      add(:address_street, :string)
      add(:address_city, :string)
      add(:address_province, ProvinceEnum.type(), default: "Ontario")
      add(:address_postal_code, :string)
      add(:address_country, :string, default: "Canada")

      timestamps()
    end

    alter table(:people) do
      add(:profile_id, references(:profiles))
    end
  end

  def down do
    drop table(:profiles)

    alter table(:people) do
      remove(:profile_id)
    end

    ProvinceEnum.remove_type()
  end
end
