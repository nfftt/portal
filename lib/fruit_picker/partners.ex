defmodule FruitPicker.Partners do
  @moduledoc """
  The Partners context.
  """

  import Logger
  import Ecto.Query, warn: false

  alias FruitPicker.Repo
  alias FruitPicker.Partners.Agency

  alias FruitPicker.Activities.{
    Pick,
    PickFruit
  }

  alias FruitPicker.Accounts.Person

  @agency_select [
    :id,
    :name,
    :address,
    :closest_intersection,
    :contact_name,
    :contact_number,
    :is_accepting_fruit
  ]

  def list_agencies do
    Agency
    |> select(^@agency_select)
    |> Repo.all()
  end

  def list_agencies(page) do
    Agency
    |> select(^@agency_select)
    |> Repo.paginate(page: page)
  end

  def list_agencies(page, sort_by, desc \\ false) do
    Agency
    |> join(:left, [a], p in Pick, on: a.id == p.agency_id)
    |> join(:left, [a, p], pf in PickFruit, on: p.id == pf.pick_id)
    |> group_by([a, p, pf], a.id)
    |> select([a, p, pf], %Agency{
      id: a.id,
      name: a.name,
      address: a.address,
      closest_intersection: a.closest_intersection,
      contact_name: a.contact_name,
      contact_number: a.contact_number,
      is_accepting_fruit: a.is_accepting_fruit,
      total_pounds_donated: sum(pf.total_pounds_donated)
    })
    |> sort_agencies_query(sort_by, desc)
    |> Repo.paginate(page: page)
  end

  @doc """
  Returns all fields for all agencies
  """
  def list_all_agencies() do
    Agency
    |> Repo.all()
  end


  def list_agencies_accepting_fruit do
    Agency
    |> select(^@agency_select)
    |> where(is_accepting_fruit: true)
    |> Repo.all()
  end

  def list_agencies_available(date, start_time) do
    start_time = Time.from_iso8601!(start_time)
    end_time = Time.add(start_time, 7200, :second)

    day =
      date
      |> Date.from_iso8601!()
      |> Timex.format!("%A", :strftime)
      |> String.downcase()

    day_start_time = String.to_existing_atom("#{day}_hours_start")
    day_end_time = String.to_existing_atom("#{day}_hours_end")
    day_closed = String.to_existing_atom("#{day}_closed")

    Agency
    |> where([a], field(a, ^day_closed) == false)
    |> where([a], field(a, ^day_start_time) <= ^start_time)
    |> where([a], field(a, ^day_end_time) >= ^end_time)
    |> Repo.all()
  end

  def list_agencies_available_to_report(date, start_time) do
    end_time = Time.add(start_time, 7200, :second)

    day =
      date
      |> Timex.format!("%A", :strftime)
      |> String.downcase()

    day_start_time = String.to_existing_atom("#{day}_hours_start")
    day_end_time = String.to_existing_atom("#{day}_hours_end")
    day_closed = String.to_existing_atom("#{day}_closed")

    Agency
    |> where([a], field(a, ^day_closed) == false)
    |> where([a], field(a, ^day_start_time) <= ^start_time)
    |> where([a], field(a, ^day_end_time) >= ^end_time)
    |> Repo.all()
  end

  # TODO: list agencies that are accepting fruit matching a list
  # which can be used to match against a pick with a list of fruit
  # being picked from categories of trees

  def change_agency(%Agency{} = agency) do
    Agency.changeset(agency, %{})
  end

  def create_agency(attrs \\ %{}) do
    %Agency{}
    |> Agency.changeset(attrs)
    |> Repo.insert()
  end

  def get_agency!(id), do: Agency |> Repo.get!(id) |> Agency.preload_all()

  def get_my_agency!(person) do
    agencies =
      Agency
      |> where(partner_id: ^person.id)
      |> Agency.preload_all()
      |> Repo.all()

    if length(agencies) > 1 do
      Logger.error("The user with id #{person.id} is associated with more than one agency.")
    end

    Enum.at(agencies, 0)
  end

  def update_agency(%Agency{} = agency, attrs) do
    agency
    |> Agency.changeset(attrs)
    |> Repo.update()
  end

  def delete_agency(%Agency{} = agency) do
    Repo.delete(agency)
  end

  def get_scheduled_picks(%Agency{} = agency) do
    Pick
    |> where(agency_id: ^agency.id)
    |> where([p], p.status in [^:claimed])
    |> Pick.preload_trees()
    |> Repo.all()
  end

  def get_scheduled_picks(nil) do
    []
  end

  def get_completed_picks(%Agency{} = agency) do
    Pick
    |> where(agency_id: ^agency.id)
    |> where(status: ^:completed)
    |> join(:inner, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> group_by([pick, fruit], [pick.id])
    |> Pick.preload_trees()
    |> order_by([pick], desc: pick.scheduled_date)
    |> select([pick, fruit], %{
      pick: pick,
      pounds_picked: sum(fruit.total_pounds_picked),
      pounds_donated: sum(fruit.total_pounds_donated)
    })
    |> Repo.all()
  end

  def get_completed_picks(nil) do
    []
  end

  def get_available do
    Person
    |> where(role: "agency")
    |> join(:left, [p], a in Agency, on: a.partner_id == p.id)
    |> where([p, a], is_nil(a.partner_id))
    |> Repo.all()
  end

  defp sort_agencies_query(query, field, desc) do
    cond do
      field not in [
        "name",
        "address",
        "closest_intersection",
        "contact_name",
        "is_accepting_fruit"
      ] ->
        query

      desc == "true" ->
        order_by(query, desc: ^String.to_existing_atom(field))

      true ->
        order_by(query, asc: ^String.to_existing_atom(field))
    end
  end
end
