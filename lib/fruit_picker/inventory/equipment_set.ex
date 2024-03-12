defmodule FruitPicker.Inventory.EquipmentSet do
  @moduledoc """
  Data representation of equipment sets.
  """

  use FruitPicker.Schema

  alias FruitPicker.Activities.Pick

  schema "equipment_sets" do
    field(:name, :string)
    field(:address, :string)
    field(:closest_intersection, :string)
    field(:latitude, :float)
    field(:longitude, :float)
    field(:contact_name, :string)
    field(:contact_number, :string)
    field(:secondary_contact_name, :string)
    field(:secondary_contact_number, :string)
    field(:access_instructions, :string)
    field(:bike_lock_instructions, :string)
    field(:is_active, :boolean)
    field(:coordinates_updated_at, :naive_datetime_usec)

    has_many(:picks, Pick)

    timestamps()
  end

  @doc false
  def activation_changeset(equipment_set, attrs) do
    equipment_set
    |> cast(attrs, [:is_active])
    |> validate_required([:is_active])
  end

  @doc false
  def changeset(equipment_set, attrs) do
    equipment_set
    |> cast(attrs, [
      :name,
      :address,
      :closest_intersection,
      :contact_name,
      :contact_number,
      :secondary_contact_name,
      :secondary_contact_number,
      :access_instructions,
      :bike_lock_instructions
    ])
    |> validate_required([
      :name,
      :address,
      :closest_intersection,
      :contact_name,
      :contact_number,
      :access_instructions,
      :bike_lock_instructions
    ])
  end

  @doc false
  def coordinates_changeset(eqiupment_set, attrs) do
    eqiupment_set
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

  def active(query \\ __MODULE__), do: from(q in query, where: q.is_active == true)

  def preload_all(equipment_set) do
    equipment_set
    |> preload_picks()
  end

  def preload_picks(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :picks)
  def preload_picks(equipment_set), do: Repo.preload(equipment_set, :picks)
end
