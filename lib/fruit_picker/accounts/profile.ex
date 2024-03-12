defmodule FruitPicker.Accounts.Profile do
  @moduledoc """
  Data representation of profile personal information for people.
  """

  use FruitPicker.Schema

  alias FruitPicker.Accounts.{Person, Profile}

  defenum(ProvinceEnum, :province, [
    "Ontario",
    "Quebec",
    "Nova Scotia",
    "New Brunswick",
    "Manitoba",
    "British Columbia",
    "Prince Edward Island",
    "Saskatchewan",
    "Alberta",
    "Newfoundland and Labrador",
    "Northwest Territories",
    "Yukon",
    "Nunavut",
  ])

  schema "profiles" do
    field(:phone_number, :string)
    field(:secondary_phone_number, :string)
    field(:address_street, :string)
    field(:address_city, :string)
    field(:address_province, ProvinceEnum)
    field(:address_postal_code, :string)
    field(:address_country, :string)

    belongs_to(:person, Person)

    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [
        :phone_number,
        :secondary_phone_number,
        :address_street,
        :address_city,
        :address_province,
        :address_postal_code,
      ])
    |> validate_required([
      :phone_number,
      :address_street,
      :address_city,
      :address_province,
      :address_postal_code
    ])
    |> assoc_constraint(:person)
  end
end
