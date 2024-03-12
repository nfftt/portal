defmodule FruitPicker.Stats do
  @moduledoc """
  The Activities context.
  """

  import Ecto.Query, warn: false

  alias FruitPicker.Activities
  alias FruitPicker.Repo
  alias FruitPicker.Accounts.Person
  alias FruitPicker.Partners.Agency

  alias FruitPicker.Activities

  alias FruitPicker.Activities.{
    Pick,
    PickAttendance,
    PickFruit,
    PickReport
  }

  def tree_owner_season_stats(%Person{} = person) do
    today = Date.utc_today()
    {:ok, season_start} = Date.new(today.year, 5, 1)

    Pick
    |> where(requester_id: ^person.id)
    |> where(status: "completed")
    |> where([pick], pick.scheduled_date > ^season_start)
    |> join(:left, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> select([pick, fruit], %{
      "picks" => count(pick.id),
      "pounds_picked" => sum(fruit.total_pounds_picked),
      "pounds_donated" => sum(fruit.total_pounds_donated)
    })
    |> Repo.one()
  end

  def tree_owner_total_stats(%Person{} = person) do
    Pick
    |> where(requester_id: ^person.id)
    |> where(status: "completed")
    |> join(:left, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> select([pick, fruit], %{
      "picks" => count(pick.id),
      "pounds_picked" => sum(fruit.total_pounds_picked),
      "pounds_donated" => sum(fruit.total_pounds_donated)
    })
    |> Repo.one()
  end

  def lead_picker_season_stats(%Person{} = person) do
    lead_stats =
      lead_query(person.id)
      |> in_current_season()
      |> Activities.exclude_busts()
      |> get_stats()
      |> Repo.one()

    attended_stats =
      attendance_query(person.id)
      |> in_current_season()
      |> Activities.exclude_busts()
      |> get_stats()
      |> Repo.one()

    # Callers of this function expect string keys
    %{
      "picks_lead" => lead_stats[:picks],
      "picks_attended" => attended_stats[:picks],
      "pounds_picked" => lead_stats[:pounds_picked] + attended_stats[:pounds_picked],
      "pounds_donated" => lead_stats[:pounds_donated] + attended_stats[:pounds_donated]
    }
  end

  def lead_picker_total_stats(%Person{} = person) do
    lead_stats =
      lead_query(person.id)
      |> Activities.exclude_busts()
      |> get_stats()
      |> Repo.one()

    attended_stats =
      attendance_query(person.id)
      |> Activities.exclude_busts()
      |> get_stats()
      |> Repo.one()

    # Callers of this function expect string keys
    %{
      "picks_lead" => lead_stats[:picks],
      "picks_attended" => attended_stats[:picks],
      "pounds_picked" => lead_stats[:pounds_picked] + attended_stats[:pounds_picked],
      "pounds_donated" => lead_stats[:pounds_donated] + attended_stats[:pounds_donated]
    }
  end

  def picker_season_stats(%Person{} = person) do
    attended_stats =
      attendance_query(person.id)
      |> in_current_season()
      |> Activities.exclude_busts()
      |> get_stats()
      |> Repo.one()

    # Callers of this function expect string keys
    %{
      "picks" => attended_stats[:picks],
      "pounds_picked" => attended_stats[:pounds_picked],
      "pounds_donated" => attended_stats[:pounds_donated]
    }
  end

  def picker_total_stats(%Person{} = person) do
    attended_stats =
      attendance_query(person.id)
      |> Activities.exclude_busts()
      |> get_stats()
      |> Repo.one()

    # Callers of this function expect string keys
    %{
      "picks" => attended_stats[:picks],
      "pounds_picked" => attended_stats[:pounds_picked],
      "pounds_donated" => attended_stats[:pounds_donated]
    }
  end

  defp attendance_query(person_id) do
    from p in Pick,
      where: p.status == "completed",
      join: pr in assoc(p, :report),
      as: :pick_report,
      join: pa in assoc(pr, :attendees),
      as: :pick_attendence,
      where: pa.person_id == ^person_id and pa.did_attend == true
  end

  defp lead_query(person_id) do
    from p in Pick,
      where: p.status == "completed",
      where: p.lead_picker_id == ^person_id
  end

  defp in_current_season(query) do
    today = Date.utc_today()
    {:ok, season_start} = Date.new(today.year, 5, 1)

    from p in query,
      where: p.scheduled_date > ^season_start
  end

  defp get_stats(query) do
    from [p, pick_fruits: pf] in Activities.with_pick_fruits(query),
      select: %{
        picks: count(p.id) |> coalesce(0),
        pounds_picked: sum(pf.total_pounds_picked) |> coalesce(0),
        pounds_donated: sum(pf.total_pounds_donated) |> coalesce(0)
      }
  end

  def agency_season_stats(%Person{} = person) do
    today = Date.utc_today()
    {:ok, season_start} = Date.new(today.year, 5, 1)

    Pick
    |> join(:left, [pick], agency in Agency, on: agency.id == pick.agency_id)
    |> where([pick, agency], agency.partner_id == ^person.id and pick.status == "completed")
    |> where([pick, _], pick.scheduled_date > ^season_start)
    |> join(:left, [pick, _], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> select([pick, _, fruit], %{
      "picks" => count(pick.id),
      "pounds_donated" => sum(fruit.total_pounds_donated)
    })
    |> Repo.one()
  end

  def agency_total_stats(%Person{} = person) do
    Pick
    |> join(:left, [pick], agency in Agency, on: agency.id == pick.agency_id)
    |> where([pick, agency], agency.partner_id == ^person.id and pick.status == "completed")
    |> join(:left, [pick, _], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> select([pick, _, fruit], %{
      "picks" => count(pick.id),
      "pounds_donated" => sum(fruit.total_pounds_donated)
    })
    |> Repo.one()
  end

  def get_missed_picks_count(%Person{} = person) do
    year = Date.utc_today().year

    beginning = Date.from_erl!({year, 1, 1})
    ending = Date.from_erl!({year, 12, 31})

    PickAttendance
    |> where([pa], did_attend: false)
    |> join(:inner, [pa], pr in PickReport, on: pa.pick_report_id == pr.id)
    |> join(:inner, [pa, pr], p in Pick, on: pr.pick_id == p.id)
    |> where([pa, pr, p], pa.person_id == ^person.id)
    |> where([pa, pr, p], p.scheduled_date >= ^beginning)
    |> where([pa, pr, p], p.scheduled_date <= ^ending)
    |> Repo.aggregate(:count, :id)
  end
end
