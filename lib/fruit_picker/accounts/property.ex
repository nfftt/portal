defmodule FruitPicker.Accounts.Property do
  @moduledoc """
  Data representation of a person's property, which contains trees.
  """

  use FruitPicker.Schema

  alias FruitPicker.Accounts.{
    Person,
    Tree
  }

  schema "properties" do
    field(:my_role, :string)
    field(:address_street, :string)
    field(:address_closest_intersection, :string)
    field(:address_city, :string)
    field(:address_postal_code, :string)
    field(:address_province, :string)
    field(:address_country, :string)
    field(:latitude, :float)
    field(:longitude, :float)
    field(:ladder_provided, :string)
    field(:tree_owner_takes, :string)
    field(:notes, :string)

    field(:is_in_operating_area, :boolean)
    field(:coordinates_updated_at, :naive_datetime_usec)

    belongs_to(:person, Person)
    has_many(:trees, Tree)

    timestamps()
  end

  @doc false
  def changeset(property, attrs) do
    property
    |> cast(attrs, [
      :my_role,
      :address_street,
      :address_closest_intersection,
      :address_city,
      :address_postal_code,
      :ladder_provided,
      :tree_owner_takes,
      :notes
    ])
    |> validate_required([
      :my_role,
      :address_street,
      :address_closest_intersection,
      :address_city,
      :address_postal_code,
      :notes
    ])
    |> assoc_constraint(:person)
  end

  @doc false
  def admin_changeset(property, attrs) do
    property
    |> cast(attrs, [
      :my_role,
      :address_street,
      :address_closest_intersection,
      :address_city,
      :address_postal_code,
      :ladder_provided,
      :tree_owner_takes,
      :notes,
      :is_in_operating_area
    ])
    |> validate_required([
      :my_role,
      :address_street,
      :address_closest_intersection,
      :address_city,
      :address_postal_code,
      :notes
    ])
    |> assoc_constraint(:person)
  end

  @doc false
  def coordinates_changeset(property, attrs) do
    property
    |> cast(attrs, [
      :latitude,
      :longitude
    ])
    |> validate_required([
      :latitude,
      :longitude
    ])
    |> put_change(
      :coordinates_updated_at,
      NaiveDateTime.utc_now()
    )
  end
end
