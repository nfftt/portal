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

  def tree_owner_season_stats(people) when is_list(people) do
    today = Date.utc_today()
    {:ok, season_start} = Date.new(today.year, 5, 1)

    Pick
    |> where([pick], pick.requester_id in ^Enum.map(people, & &1.id))
    |> where(status: "completed")
    |> where([pick], pick.scheduled_date > ^season_start)
    |> join(:left, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> group_by([pick], pick.requester_id)
    |> select(
      [pick, fruit],
      {pick.requester_id,
       %{
         picks: count(pick.id),
         pounds_picked: sum(fruit.total_pounds_picked),
         pounds_donated: sum(fruit.total_pounds_donated)
       }}
    )
    |> Repo.all()
    |> Map.new()
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

  def tree_owner_total_stats(people) when is_list(people) do
    Pick
    |> where([pick], pick.requester_id in ^Enum.map(people, & &1.id))
    |> where(status: "completed")
    |> join(:left, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> group_by([pick], pick.requester_id)
    |> select(
      [pick, fruit],
      {pick.requester_id,
       %{
         picks: count(pick.id),
         pounds_picked: sum(fruit.total_pounds_picked),
         pounds_donated: sum(fruit.total_pounds_donated)
       }}
    )
    |> Repo.all()
    |> Map.new()
  end

  def lead_picker_season_stats(%Person{} = person) do
    lead_stats =
      lead_query(person.id)
      |> in_current_season()
      |> Activities.exclude_busts()
      |> get_lead_stats()
      |> Repo.one()

    attended_stats =
      attendance_query(person.id)
      |> in_current_season()
      |> Activities.exclude_busts()
      |> get_attendance_stats()
      |> Repo.one()

    # We may get nils if the person has not been a lead or attended any picks
    lead_stats =
      lead_stats ||
        %{
          person_id: person.id,
          picks: 0,
          pounds_picked: 0,
          pounds_donated: 0
        }

    attended_stats =
      attended_stats ||
        %{
          person_id: person.id,
          picks: 0,
          pounds_picked: 0,
          pounds_donated: 0
        }

    # Callers of this function expect string keys
    %{
      "picks_lead" => lead_stats[:picks],
      "picks_attended" => attended_stats[:picks],
      "pounds_picked" => lead_stats[:pounds_picked] + attended_stats[:pounds_picked],
      "pounds_donated" => lead_stats[:pounds_donated] + attended_stats[:pounds_donated]
    }
  end

  def lead_picker_season_stats(lead_pickers) when is_list(lead_pickers) do
    lead_stats =
      lead_pickers
      |> Enum.map(& &1.id)
      |> lead_query()
      |> in_current_season()
      |> Activities.exclude_busts()
      |> get_lead_stats()
      |> Repo.all()
      |> Map.new(&{&1[:person_id], &1})

    attended_stats =
      lead_pickers
      |> Enum.map(& &1.id)
      |> attendance_query()
      |> in_current_season()
      |> Activities.exclude_busts()
      |> get_attendance_stats()
      |> Repo.all()
      |> Map.new(&{&1[:person_id], &1})

    for %{id: id} <- lead_pickers, into: %{} do
      lead =
        Map.get(lead_stats, id, %{
          person_id: id,
          picks: 0,
          pounds_picked: 0,
          pounds_donated: 0
        })

      attended =
        Map.get(attended_stats, id, %{
          person_id: id,
          picks: 0,
          pounds_picked: 0,
          pounds_donated: 0
        })

      {id,
       %{
         person_id: id,
         picks: lead.picks + attended.picks,
         picks_lead: lead.picks,
         picks_attended: attended.picks,
         pounds_picked: lead.pounds_picked + attended.pounds_picked,
         pounds_donated: lead.pounds_donated + attended.pounds_donated
       }}
    end
  end

  def lead_picker_total_stats(%Person{} = person) do
    lead_stats =
      lead_query(person.id)
      |> Activities.exclude_busts()
      |> get_lead_stats()
      |> Repo.one()

    attended_stats =
      attendance_query(person.id)
      |> Activities.exclude_busts()
      |> get_attendance_stats()
      |> Repo.one()

    # We may get nils if the person has not been a lead or attended any picks
    lead_stats =
      lead_stats ||
        %{
          person_id: person.id,
          picks: 0,
          pounds_picked: 0,
          pounds_donated: 0
        }

    attended_stats =
      attended_stats ||
        %{
          person_id: person.id,
          picks: 0,
          pounds_picked: 0,
          pounds_donated: 0
        }

    # Callers of this function expect string keys
    %{
      "picks_lead" => lead_stats[:picks],
      "picks_attended" => attended_stats[:picks],
      "pounds_picked" => lead_stats[:pounds_picked] + attended_stats[:pounds_picked],
      "pounds_donated" => lead_stats[:pounds_donated] + attended_stats[:pounds_donated]
    }
  end

  def lead_picker_total_stats(lead_pickers) when is_list(lead_pickers) do
    lead_stats =
      lead_pickers
      |> Enum.map(& &1.id)
      |> lead_query()
      |> Activities.exclude_busts()
      |> get_lead_stats()
      |> Repo.all()
      |> Map.new(&{&1[:person_id], &1})

    attended_stats =
      lead_pickers
      |> Enum.map(& &1.id)
      |> attendance_query()
      |> Activities.exclude_busts()
      |> get_attendance_stats()
      |> Repo.all()
      |> Map.new(&{&1[:person_id], &1})

    for %{id: id} <- lead_pickers, into: %{} do
      lead =
        Map.get(lead_stats, id, %{
          person_id: id,
          picks: 0,
          pounds_picked: 0,
          pounds_donated: 0
        })

      attended =
        Map.get(attended_stats, id, %{
          person_id: id,
          picks: 0,
          pounds_picked: 0,
          pounds_donated: 0
        })

      {id,
       %{
         person_id: id,
         picks: lead[:picks] + attended[:picks],
         picks_lead: lead.picks,
         picks_attended: attended.picks,
         pounds_picked: lead.pounds_picked + attended.pounds_picked,
         pounds_donated: lead.pounds_donated + attended.pounds_donated
       }}
    end
  end

  def picker_season_stats(%Person{} = person) do
    attended_stats =
      attendance_query(person.id)
      |> in_current_season()
      |> Activities.exclude_busts()
      |> get_attendance_stats()
      |> Repo.one()

    # We may get nils if the person has not been a lead or attended any picks
    attended_stats =
      attended_stats ||
        %{
          person_id: person.id,
          picks: 0,
          pounds_picked: 0,
          pounds_donated: 0
        }

    # Callers of this function expect string keys
    %{
      "picks" => attended_stats[:picks],
      "pounds_picked" => attended_stats[:pounds_picked],
      "pounds_donated" => attended_stats[:pounds_donated]
    }
  end

  def picker_season_stats(pickers) when is_list(pickers) do
    pickers
    |> Enum.map(& &1.id)
    |> attendance_query()
    |> in_current_season()
    |> Activities.exclude_busts()
    |> get_attendance_stats()
    |> Repo.all()
    |> Map.new(&{&1[:person_id], &1})
  end

  def picker_total_stats(%Person{} = person) do
    attended_stats =
      attendance_query(person.id)
      |> Activities.exclude_busts()
      |> get_attendance_stats()
      |> Repo.one()

    # We may get nils if the person has not been a lead or attended any picks
    attended_stats =
      attended_stats ||
        %{
          person_id: person.id,
          picks: 0,
          pounds_picked: 0,
          pounds_donated: 0
        }

    # Callers of this function expect string keys
    %{
      "picks" => attended_stats[:picks],
      "pounds_picked" => attended_stats[:pounds_picked],
      "pounds_donated" => attended_stats[:pounds_donated]
    }
  end

  def picker_total_stats(pickers) when is_list(pickers) do
    pickers
    |> Enum.map(& &1.id)
    |> attendance_query()
    |> Activities.exclude_busts()
    |> get_attendance_stats()
    |> Repo.all()
    |> Map.new(&{&1[:person_id], &1})
  end

  def attendance_query() do
    from p in Pick,
      where: p.status == "completed",
      join: pr in assoc(p, :report),
      as: :pick_report,
      join: pa in assoc(pr, :attendees),
      as: :pick_attendance,
      where: pa.did_attend == true
  end

  defp attendance_query(person_id) when is_number(person_id) do
    from [pick_attendance: pa] in attendance_query(),
      where: pa.person_id == ^person_id
  end

  defp attendance_query(people_ids) when is_list(people_ids) do
    from [pick_attendance: pa] in attendance_query(),
      where: pa.person_id in ^people_ids
  end

  defp lead_query(person_id) when is_number(person_id) do
    from p in Pick,
      where: p.status == "completed",
      where: p.lead_picker_id == ^person_id
  end

  defp lead_query(people_ids) when is_list(people_ids) do
    from p in Pick,
      where: p.status == "completed",
      where: p.lead_picker_id in ^people_ids
  end

  defp in_current_season(query) do
    today = Date.utc_today()
    {:ok, season_start} = Date.new(today.year, 5, 1)

    from p in query,
      where: p.scheduled_date > ^season_start
  end

  def get_attendance_stats(query) do
    from [p, pick_fruits: pf, pick_attendance: pa] in Activities.with_pick_fruits(query),
      group_by: pa.person_id,
      select: %{
        person_id: pa.person_id,
        picks: count(p.id) |> coalesce(0),
        pounds_picked: sum(pf.total_pounds_picked) |> coalesce(0),
        pounds_donated: sum(pf.total_pounds_donated) |> coalesce(0)
      }
  end

  def get_lead_stats(query) do
    from [p, pick_fruits: pf] in Activities.with_pick_fruits(query),
      group_by: p.lead_picker_id,
      select: %{
        person_id: p.lead_picker_id,
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

  def agency_season_stats(people) when is_list(people) do
    today = Date.utc_today()
    {:ok, season_start} = Date.new(today.year, 5, 1)

    Pick
    |> join(:left, [pick], agency in Agency, on: agency.id == pick.agency_id)
    |> where(
      [pick, agency],
      agency.partner_id in ^Enum.map(people, & &1.id) and pick.status == "completed"
    )
    |> where([pick, _], pick.scheduled_date > ^season_start)
    |> join(:left, [pick, _], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> group_by([_pick, agency], agency.partner_id)
    |> select(
      [pick, agency, fruit],
      {agency.partner_id,
       %{
         picks: count(pick.id),
         pounds_donated: sum(fruit.total_pounds_donated)
       }}
    )
    |> Repo.all()
    |> Map.new()
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

  def agency_total_stats(people) when is_list(people) do
    Pick
    |> join(:left, [pick], agency in Agency, on: agency.id == pick.agency_id)
    |> where(
      [pick, agency],
      agency.partner_id in ^Enum.map(people, & &1.id) and pick.status == "completed"
    )
    |> join(:left, [pick, _], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> group_by([_pick, agency], agency.partner_id)
    |> select(
      [pick, agency, fruit],
      {agency.partner_id,
       %{
         picks: count(pick.id),
         pounds_donated: sum(fruit.total_pounds_donated)
       }}
    )
    |> Repo.all()
    |> Map.new()
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
