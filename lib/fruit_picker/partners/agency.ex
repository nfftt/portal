defmodule FruitPicker.Partners.Agency do
  @moduledoc """
  Data representation of agencies.
  """

  use FruitPicker.Schema

  alias FruitPicker.Accounts.Person
  alias FruitPicker.Activities.Pick

  schema "agencies" do
    field(:name, :string)
    field(:address, :string)
    field(:closest_intersection, :string)
    field(:latitude, :float)
    field(:longitude, :float)
    field(:contact_name, :string)
    field(:contact_email, :string)
    field(:contact_number, :string)
    field(:secondary_contact_name, :string)
    field(:secondary_contact_email, :string)
    field(:secondary_contact_number, :string)
    field(:is_accepting_fruit, :boolean)
    field(:special_instructions, :string)
    field(:total_pounds_donated, :float, virtual: true)

    # wanted fruit
    field(:accepting_sweet_cherries, :boolean)
    field(:accepting_sour_cherries, :boolean)
    field(:accepting_serviceberries, :boolean)
    field(:accepting_mulberries, :boolean)
    field(:accepting_apricots, :boolean)
    field(:accepting_crabapples, :boolean)
    field(:accepting_plums, :boolean)
    field(:accepting_apples, :boolean)
    field(:accepting_pears, :boolean)
    field(:accepting_grapes, :boolean)
    field(:accepting_elderberries, :boolean)
    field(:accepting_gingko, :boolean)
    field(:accepting_black_walnuts, :boolean)
    field(:accepting_quince, :boolean)
    field(:accepting_pawpaw, :boolean)

    # scheduling fields
    field(:sunday_hours_start, :time)
    field(:sunday_hours_end, :time)
    field(:sunday_closed, :boolean)
    field(:monday_hours_start, :time)
    field(:monday_hours_end, :time)
    field(:monday_closed, :boolean)
    field(:tuesday_hours_start, :time)
    field(:tuesday_hours_end, :time)
    field(:tuesday_closed, :boolean)
    field(:wednesday_hours_start, :time)
    field(:wednesday_hours_end, :time)
    field(:wednesday_closed, :boolean)
    field(:thursday_hours_start, :time)
    field(:thursday_hours_end, :time)
    field(:thursday_closed, :boolean)
    field(:friday_hours_start, :time)
    field(:friday_hours_end, :time)
    field(:friday_closed, :boolean)
    field(:saturday_hours_start, :time)
    field(:saturday_hours_end, :time)
    field(:saturday_closed, :boolean)
    field(:coordinates_updated_at, :naive_datetime_usec)

    belongs_to(:partner, Person)
    has_many(:picks, Pick)

    timestamps()
  end

  @doc false
  def changeset(agency, attrs) do
    agency
    |> cast(attrs, [
      :name,
      :address,
      :closest_intersection,
      :contact_name,
      :contact_email,
      :contact_number,
      :secondary_contact_name,
      :secondary_contact_email,
      :secondary_contact_number,
      :is_accepting_fruit,
      :special_instructions,
      :accepting_sweet_cherries,
      :accepting_sour_cherries,
      :accepting_serviceberries,
      :accepting_mulberries,
      :accepting_apricots,
      :accepting_crabapples,
      :accepting_plums,
      :accepting_apples,
      :accepting_pears,
      :accepting_grapes,
      :accepting_elderberries,
      :accepting_gingko,
      :accepting_black_walnuts,
      :accepting_quince,
      :accepting_pawpaw,
      :sunday_hours_start,
      :sunday_hours_end,
      :sunday_closed,
      :monday_hours_start,
      :monday_hours_end,
      :monday_closed,
      :tuesday_hours_start,
      :tuesday_hours_end,
      :tuesday_closed,
      :wednesday_hours_start,
      :wednesday_hours_end,
      :wednesday_closed,
      :thursday_hours_start,
      :thursday_hours_end,
      :thursday_closed,
      :friday_hours_start,
      :friday_hours_end,
      :friday_closed,
      :saturday_hours_start,
      :saturday_hours_end,
      :saturday_closed,
      :partner_id
    ])
    |> validate_required([
      :name,
      :address,
      :closest_intersection,
      :contact_name,
      :contact_email,
      :contact_number,
      :is_accepting_fruit,
      :accepting_sweet_cherries,
      :accepting_sour_cherries,
      :accepting_serviceberries,
      :accepting_mulberries,
      :accepting_apricots,
      :accepting_crabapples,
      :accepting_plums,
      :accepting_apples,
      :accepting_pears,
      :accepting_grapes,
      :accepting_elderberries,
      :accepting_gingko,
      :accepting_black_walnuts,
      :accepting_quince,
      :accepting_pawpaw
    ])
    |> validate_day("sunday")
    |> validate_day("monday")
    |> validate_day("tuesday")
    |> validate_day("wednesday")
    |> validate_day("thursday")
    |> validate_day("friday")
    |> validate_day("saturday")
  end

  @doc false
  def coordinates_changeset(agency, attrs) do
    agency
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

  def preload_all(agency) do
    agency
    |> preload_partner()
  end

  def accepting_fruit(query \\ __MODULE__),
    do: from(q in query, where: q.is_accepting_fruit == true)

  def preload_partner(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :partner)
  def preload_partner(agency), do: Repo.preload(agency, :partner)

  defp validate_day(changeset, day) do
    hours_start = get_field(changeset, String.to_existing_atom("#{day}_hours_start"))
    hours_end = get_field(changeset, String.to_existing_atom("#{day}_hours_end"))
    closed = get_field(changeset, String.to_existing_atom("#{day}_closed"))

    if !closed and (is_nil(hours_start) || is_nil(hours_end)) do
      add_error(
        changeset,
        String.to_existing_atom("#{day}_hours_start"),
        "Must either be closed or have start and end hours."
      )
    else
      changeset
    end
  end
end
