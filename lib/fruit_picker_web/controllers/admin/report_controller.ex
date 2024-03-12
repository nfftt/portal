defmodule FruitPickerWeb.Admin.ReportController do
  use FruitPickerWeb, :controller

  import Ecto.Query, warn: false

  alias FruitPicker.Accounts.{
    Person,
    Property,
    Tree,
    MembershipPayment
  }

  alias FruitPicker.Partners.Agency

  alias FruitPicker.Activities

  alias FruitPicker.Activities.{
    Pick,
    PickAttendance,
    PickReport,
    PickFruit,
    PickFruitAgency
  }

  alias FruitPicker.Stats
  alias FruitPicker.Repo

  def index(conn, %{"year" => report_year}) do
    season_years = Activities.get_season_years()
    year = String.to_integer(report_year)

    render(conn, "index.html",
      season_years: season_years,
      report_year: report_year,
      picking_summary: picking_summary(year),
      picker_summary: picker_summary(year),
      attendance_summary: attendance_summary(year),
      tree_registrant_details: tree_registrant_details(year),
      agency_details: agency_details(year)
    )
  end

  def index(conn, _params) do
    [year | _] = Activities.get_season_years()

    redirect(conn, to: Routes.admin_report_path(conn, :index, year: year))
  end

  defp picking_summary(year) do
    total_pick_requests =
      Pick
      |> where([p], fragment("EXTRACT(YEAR from ?)::integer", p.start_date) == ^year)
      |> Repo.aggregate(:count, :id)

    total_picks_completed =
      Pick
      |> where([p], fragment("EXTRACT(YEAR from ?)::integer", p.start_date) == ^year)
      |> where([p], p.status == "completed")
      |> Repo.aggregate(:count, :id)

    total_picks_cancelled =
      Pick
      |> where([p], fragment("EXTRACT(YEAR from ?)::integer", p.start_date) == ^year)
      |> where([p], p.status == "canceled")
      |> Repo.aggregate(:count, :id)

    total_busts =
      PickFruit
      |> where([pf], fragment("EXTRACT(YEAR from ?)::integer", pf.inserted_at) == ^year)
      |> where([pf], pf.total_pounds_donated == 0.0)
      |> Repo.aggregate(:count, :id)

    %{
      total_pick_requests: total_pick_requests,
      total_picks_completed: total_picks_completed,
      total_picks_cancelled: total_picks_cancelled,
      total_busts: total_busts
    }
  end

  defp picker_summary(year) do
    total_active_pickers =
      Person
      |> join(:inner, [p], mp in MembershipPayment, on: p.id == mp.member_id)
      |> where(
        [p, mp],
        fragment("EXTRACT(YEAR from ?)::integer", mp.start_date) == ^year
      )
      |> where(
        [p, pf],
        p.is_picker == true or p.is_lead_picker == true
      )
      |> Repo.aggregate(:count, :id)

    total_pick_leaders =
      Person
      |> join(:inner, [p], mp in MembershipPayment, on: p.id == mp.member_id)
      |> where(
        [p, mp],
        fragment("EXTRACT(YEAR from ?)::integer", mp.start_date) == ^year
      )
      |> where([p, mp], p.is_lead_picker == true)
      |> Repo.aggregate(:count, :id)

    total_non_lead_pickers =
      Person
      |> join(:inner, [p], mp in MembershipPayment, on: p.id == mp.member_id)
      |> where(
        [p, mp],
        fragment("EXTRACT(YEAR from ?)::integer", mp.start_date) == ^year
      )
      |> where([p, mp], p.is_picker == true)
      |> Repo.aggregate(:count, :id)

    %{
      total_active_pickers: total_active_pickers,
      total_pick_leaders: total_pick_leaders,
      total_non_lead_pickers: total_non_lead_pickers
    }
  end

  defp attendance_summary(year) do
    pickers_at_least_one_pick =
      PickAttendance
      |> where([pa], fragment("EXTRACT(YEAR from ?)::integer", pa.inserted_at) == ^year)
      |> where([pa], pa.did_attend == true)
      |> group_by([pa], pa.person_id)
      |> select([pa], pa.person_id)
      |> having([pa], count(pa.id) >= 1)
      |> Repo.all()
      |> length()

    active_pickers_zero_picks =
      Person
      |> join(:inner, [p], mp in MembershipPayment, on: p.id == mp.member_id)
      |> where(
        [p, mp],
        fragment("EXTRACT(YEAR from ?)::integer", mp.start_date) == ^year
      )
      |> where([p, mp], p.is_picker or p.is_lead_picker)
      |> join(:left, [p, mp], a in PickAttendance, on: p.id == a.person_id)
      |> where([p, mp, a], is_nil(a.person_id))
      |> Repo.aggregate(:count, :id)

    pickers_at_least_five_picks =
      PickAttendance
      |> where([pa], fragment("EXTRACT(YEAR from ?)::integer", pa.inserted_at) == ^year)
      |> where([pa], pa.did_attend == true)
      |> group_by([pa], pa.person_id)
      |> select([pa], pa.person_id)
      |> having([pa], count(pa.id) >= 5)
      |> Repo.all()
      |> length()

    %{
      pickers_at_least_one_pick: pickers_at_least_one_pick,
      active_pickers_zero_picks: active_pickers_zero_picks,
      pickers_at_least_five_picks: pickers_at_least_five_picks
    }
  end

  defp tree_registrant_details(year) do
    registered_trees =
      Tree
      |> where([t], fragment("EXTRACT(YEAR from ?)::integer", t.inserted_at) == ^year)
      |> Repo.aggregate(:count, :id)

    %{
      registered_trees: registered_trees
    }
  end

  defp tree_registrant_details() do
    registered_trees = Repo.aggregate(Tree, :count, :id)

    %{
      registered_trees: registered_trees
    }
  end

  defp agency_details(year) do
    agencies_registered =
      Agency
      |> where(
        [a],
        fragment("EXTRACT(YEAR from ?)::integer", a.inserted_at) == ^year
      )
      |> Repo.aggregate(:count, :id)

    active_agencies =
      Person
      |> where([p], p.role == "agency")
      |> join(:inner, [p], mp in MembershipPayment, on: p.id == mp.member_id)
      |> where(
        [p, mp],
        fragment("EXTRACT(YEAR from ?)::integer", mp.start_date) == ^year
      )
      |> Repo.aggregate(:count, :id)

    new_agencies_this_year =
      Person
      |> where([p], p.role == "agency")
      |> where(
        [p],
        fragment("EXTRACT(YEAR from ?)::integer", p.inserted_at) == ^year
      )
      |> Repo.aggregate(:count, :id)

    total_agencies_received_fruit =
      pick_fruit_agencies =
      PickFruitAgency
      |> where([pfa], fragment("EXTRACT(YEAR from ?)::integer", pfa.inserted_at) == ^year)
      |> group_by([pfa], pfa.agency_id)
      |> select([pfa], pfa.agency_id)
      |> Repo.all()
      |> length()

    total_agencies_no_received_fruit = agencies_registered - total_agencies_received_fruit

    %{
      agencies_registered: agencies_registered,
      active_agencies: active_agencies,
      new_agencies_this_year: new_agencies_this_year,
      total_agencies_received_fruit: total_agencies_received_fruit,
      total_agencies_no_received_fruit: total_agencies_no_received_fruit
    }
  end
end
