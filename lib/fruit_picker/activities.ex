defmodule FruitPicker.Activities do
  @moduledoc """
  The Activities context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias FruitPicker.Repo

  alias FruitPicker.Accounts.{
    Person,
    Tree,
    TreeSnapshot
  }

  alias FruitPicker.Activities

  alias FruitPicker.Activities.{
    Pick,
    PickAttendance,
    PickFruit,
    PickPerson,
    PickReport,
    PickTree
  }

  alias Ecto.Multi

  def change_pick(%Pick{} = pick) do
    Pick.changeset(pick, %{})
  end

  def create_pick(attrs \\ %{}, requester, trees) do
    %Pick{}
    |> Pick.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:requester, requester)
    |> Ecto.Changeset.put_assoc(:trees, trees)
    |> Ecto.Changeset.assoc_constraint(:requester)
    |> validate_tree_count([])
    |> Repo.insert()
  end

  def admin_create_pick(attrs \\ %{}, requester, trees) do
    case create_pick(attrs, requester, trees) do
      {:ok, pick} -> submit_pick(pick)
      error -> error
    end
  end

  def update_pick(%Pick{} = pick, trees, attrs \\ %{}) do
    pick
    |> Pick.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:trees, trees)
    |> Ecto.Changeset.assoc_constraint(:requester)
    |> validate_tree_count(pick.trees)
    |> Repo.update()
  end

  def admin_update_pick(%Pick{} = pick, trees, attrs \\ %{}) do
    pick
    |> Pick.admin_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:trees, trees)
    |> Ecto.Changeset.assoc_constraint(:requester)
    |> validate_tree_count(pick.trees)
    |> Repo.update()
  end

  def update_pick_fruits(pick_report, pick_id) do
    report = get_pick_report_with_agencies(pick_id)

    PickReport.changeset(report, pick_report)
    |> Repo.update()
  end

  def create_report(attrs \\ %{}, pick, submitter, attendees \\ []) do
    pick_report_changeset =
      %PickReport{}
      |> Ecto.Changeset.change(pick_id: pick.id)
      |> Ecto.Changeset.change(submitter_id: submitter.id)
      |> PickReport.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:submitter, submitter)
      |> Ecto.Changeset.put_assoc(:pick, pick)
      |> Ecto.Changeset.assoc_constraint(:submitter)
      |> Ecto.Changeset.assoc_constraint(:pick)

    Multi.new()
    |> Multi.insert(:pick_report, pick_report_changeset)
    |> Multi.run(:attendance, fn repo, %{pick_report: report} ->
      attendance_maps =
        Enum.map(attendees, fn a ->
          %{
            inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
            updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
            did_attend: elem(a, 1) == "true",
            pick_report_id: report.id,
            person_id: String.to_integer(elem(a, 0))
          }
        end)

      attendance_changesets =
        Enum.map(attendance_maps, fn a ->
          PickAttendance.changeset(%PickAttendance{}, a)
        end)

      if Enum.any?(attendance_changesets, fn ac -> length(ac.errors) > 0 end) do
        {:error, "Error saving attendance"}
      else
        {count, _} = repo.insert_all(PickAttendance, attendance_maps)
        {:ok, count}
      end
    end)
    |> Repo.transaction()
  end

  def complete_report(%PickReport{} = pick_report, attrs \\ %{}) do
    pick_report
    |> PickReport.changeset(attrs)
    |> Ecto.Changeset.change(is_complete: true)
    |> Repo.update()
  end

  def update_report(pick_report_id, attrs) do
    pick_report = get_pick_report!(pick_report_id)

    PickReport.changeset(pick_report, attrs)
    |> Repo.update()
  end

  def get_attendee(id) do
    PickAttendance
    |> Repo.get!(id)
  end

  def update_attendees(attendees) do
    Multi.new()
    |> Multi.run(:attendees, fn _x, _y ->
      case Enum.map(attendees, fn attendee ->
             attendee_struct = get_attendee(attendee["id"])

             Ecto.Changeset.change(attendee_struct,
               did_attend: if(attendee["did_attend"] == "true", do: true, else: false)
             )
             |> Repo.update()
           end)
           |> Enum.all?(fn {k, _v} -> k == :ok end) do
        true -> {:ok, nil}
        false -> {:error, nil}
      end
    end)
    |> Repo.transaction()
  end

  def pick_count, do: Repo.aggregate(Pick, :count, :id)
  def pick_request_count, do: Repo.count(from(q in Pick, where: q.status == "submitted"))

  def list_picks do
    query = from(p in Pick)

    query
    |> Pick.preload_list()
    |> Repo.all()
  end

  def list_picks(page) do
    query = from(p in Pick)

    query
    |> Pick.preload_list()
    |> Repo.paginate(page: page)
  end

  def list_picks(page, sort_by, desc \\ false) do
    query = from(p in Pick)

    query
    |> sort_picks_query(sort_by, desc)
    |> Pick.preload_list()
    |> Repo.paginate(page: page)
  end

  def list_picks_by_status(status, page, sort_by, desc \\ false) do
    Pick
    |> where(status: ^status)
    |> sort_picks_query(sort_by, desc)
    |> Pick.preload_list()
    |> Repo.paginate(page: page)
  end

  def list_completed_picks(page, sort_by, desc \\ false) do
    Pick
    |> where(status: "completed")
    |> sort_picks_query(sort_by, desc)
    |> join(:left, [pick], fruit in PickFruit, as: :fruit, on: fruit.pick_id == pick.id)
    |> preload([:report, :trees, :lead_picker, :pickers])
    |> group_by([pick], pick.id)
    |> select([pick, fruit: fruit], %{pick: pick, pounds_picked: sum(fruit.total_pounds_picked)})
    |> Repo.paginate(page: page)
  end

  def summary_picks_by_status(status) do
    Pick
    |> where(status: ^status)
    |> order_by(asc: :scheduled_date, asc: :start_date, asc: :updated_at)
    |> limit(10)
    |> Pick.preload_list()
    |> Repo.all()
  end

  def summary_picks_by_status(status1, status2) do
    Pick
    |> where(status: ^status1)
    |> or_where(status: ^status2)
    |> order_by(asc: :scheduled_date, asc: :start_date, asc: :updated_at)
    |> limit(10)
    |> Pick.preload_list()
    |> Repo.all()
  end

  def summary_available_picks_to_claim(person) do
    claimed_requested_picks =
      Pick
      |> where(requester_id: ^person.id)

    Pick
    |> where([p], p.status in [^:scheduled])
    |> where([p], is_nil(p.lead_picker_id))
    |> except_all(^claimed_requested_picks)
    |> Pick.public()
    |> Pick.preload_list()
    |> Repo.all()
  end

  def summary_available_picks_to_claim(person, sort_by, desc \\ false) do
    claimed_requested_picks =
      Pick
      |> where(requester_id: ^person.id)

    picks =
      Pick
      |> where([p], p.status in [^:scheduled])
      |> where([p], is_nil(p.lead_picker_id))
      |> except_all(^claimed_requested_picks)
      |> Pick.public()

    from(pick in subquery(picks))
    |> sort_picks_query(sort_by, desc)
    |> Pick.preload_list()
    |> Repo.all()
  end

  def summary_available_picks_to_join(person) do
    pick_person =
      PickPerson
      |> where(person_id: ^person.id)
      |> join(:inner, [pp], p in Pick, on: pp.pick_id == p.id and pp.person_id == ^person.id)
      |> select([pp, p], {p})

    claimed_requested_picks =
      Pick
      |> where(requester_id: ^person.id)
      |> or_where(lead_picker_id: ^person.id)

    Pick
    |> where(status: "claimed")
    |> where([p], not is_nil(p.lead_picker_id))
    |> except_all(^pick_person)
    |> except_all(^claimed_requested_picks)
    |> limit(20)
    |> Pick.public()
    |> Pick.preload_list()
    |> Repo.all()
  end

  def summary_available_picks_to_join(person, sort_by, desc \\ false) do
    pick_person =
      PickPerson
      |> where(person_id: ^person.id)
      |> join(:inner, [pp], p in Pick, on: pp.pick_id == p.id and pp.person_id == ^person.id)
      |> select([pp, p], {p})

    claimed_requested_picks =
      Pick
      |> where(requester_id: ^person.id)
      |> or_where(lead_picker_id: ^person.id)

    picks_query =
      Pick
      |> where(status: "claimed")
      |> where([p], not is_nil(p.lead_picker_id))
      |> except_all(^pick_person)
      |> except_all(^claimed_requested_picks)
      |> Pick.public()

    from(pick in subquery(picks_query))
    |> sort_picks_query(sort_by, desc)
    |> Pick.preload_list()
    |> Repo.all()
  end

  def summary_my_scheduled_lead_picks(person) do
    Pick
    |> where(status: "claimed")
    |> where(lead_picker_id: ^person.id)
    |> order_by(asc: :scheduled_date, asc: :start_date, asc: :updated_at)
    |> Pick.preload_list()
    |> Repo.all()
  end

  def summary_my_scheduled_lead_picks(person, sort_by, desc \\ false) do
    Pick
    |> where(status: "claimed")
    |> where(lead_picker_id: ^person.id)
    |> Pick.preload_list()
    |> sort_picks_query(sort_by, desc)
    |> Repo.all()
  end

  def summary_my_scheduled_picks(person) do
    Pick
    |> where(status: "claimed")
    |> join(:left, [p], pp in PickPerson, on: pp.person_id == ^person.id)
    |> where([p, pp], pp.pick_id == p.id)
    |> order_by(asc: :scheduled_date, asc: :start_date, asc: :updated_at)
    |> limit(10)
    |> Pick.preload_list()
    |> Repo.all()
  end

  def summary_my_scheduled_picks(person, sort_by, desc \\ false) do
    Pick
    |> where(status: "claimed")
    |> join(:left, [p], pp in PickPerson, on: pp.person_id == ^person.id)
    |> where([p, pp], pp.pick_id == p.id)
    |> Pick.preload_list()
    |> sort_picks_query(sort_by, desc)
    |> Repo.all()
  end

  def summary_my_lead_completed_picks(person) do
    Pick
    |> where(status: "completed")
    |> where(lead_picker_id: ^person.id)
    |> order_by(asc: :scheduled_date, asc: :start_date, asc: :updated_at)
    |> join(:left, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> Pick.preload_list()
    |> group_by([pick], pick.id)
    |> select([pick, fruit], %{
      pick: pick,
      pounds_picked: sum(fruit.total_pounds_picked),
      pounds_donated: sum(fruit.total_pounds_donated)
    })
    |> Repo.all()
  end

  def summary_my_lead_completed_picks(person, sort_by, desc) do
    Pick
    |> where(status: "completed")
    |> where(lead_picker_id: ^person.id)
    |> join(:left, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> Pick.preload_list()
    |> group_by([pick], pick.id)
    |> sort_picks_query(sort_by, desc)
    |> select([pick, fruit], %{
      pick: pick,
      pounds_picked: sum(fruit.total_pounds_picked),
      pounds_donated: sum(fruit.total_pounds_donated)
    })
    |> Repo.all()
  end

  def summary_my_tree_completed_picks(person) do
    Pick
    |> where(status: "completed")
    |> where(requester_id: ^person.id)
    |> order_by(desc: :updated_at)
    |> join(:left, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> Pick.preload_list()
    |> group_by([pick], pick.id)
    |> select([pick, fruit], %{
      pick: pick,
      pounds_picked: sum(fruit.total_pounds_picked),
      pounds_donated: sum(fruit.total_pounds_donated)
    })
    |> limit(10)
    |> Repo.all()
  end

  def count_pounds_this_season() do
    today = Date.utc_today()
    {:ok, season_start} = Date.new(today.year, 5, 1)

    Pick
    |> where(status: "completed")
    |> where([pick], pick.scheduled_date > ^season_start)
    |> join(:left, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> select([pick, fruit], %{
      "pounds_picked" => sum(fruit.total_pounds_picked),
      "pounds_donated" => sum(fruit.total_pounds_donated)
    })
    |> Repo.one()
  end

  def list_my_picks_by_status(%Person{} = requester, status) do
    Pick
    |> where(requester_id: ^requester.id)
    |> where(status: ^status)
    |> order_by(asc: :scheduled_date, asc: :start_date, asc: :updated_at)
    |> Pick.preload_list()
    |> Repo.all()
  end

  def list_my_picks_by_status(%Person{} = requester, status1, status2) do
    Pick
    |> where(requester_id: ^requester.id)
    |> where([p], p.status in [^status1, ^status2])
    |> order_by(asc: :scheduled_date, asc: :start_date, asc: :updated_at)
    |> Pick.preload_list()
    |> Repo.all()
  end

  def picks_with_outstanding_report(%Person{} = person) do
    from(p in picks_with_outstanding_report_query(),
      where: p.lead_picker_id == ^person.id
    )
    |> Pick.preload_lead_picker()
    |> Pick.preload_report()
    |> Repo.all()
  end

  def picks_with_outstanding_report() do
    picks_with_outstanding_report_query()
    |> Pick.preload_lead_picker()
    |> Pick.preload_report()
    |> Repo.all()
  end

  def picks_with_late_outstanding_report() do
    outstanding_date = Date.utc_today() |> Date.add(-1)

    from(p in picks_with_outstanding_report_query(),
      where: p.scheduled_date < ^outstanding_date
    )
    |> Pick.preload_all()
    |> Repo.all()
  end

  defp picks_with_outstanding_report_query() do
    from p in Pick,
      where: p.status == "completed",
      left_join: pr in PickReport,
      on: p.id == pr.pick_id and pr.is_complete == true,
      where: is_nil(pr.id)
  end

  def get_pick!(id) do
    Pick
    |> Repo.get!(id)
    |> Pick.preload_all()
  end

  def get_pick_report!(id) do
    PickReport
    |> Repo.get!(id)
    |> PickReport.preload_all()
  end

  def get_pick_report_with_agencies(pick_id) do
    PickReport
    |> where([pr], pr.pick_id == ^pick_id)
    |> Repo.one()
    |> Repo.preload(fruits: :agencies)
    |> PickReport.preload_all()
  end

  def get_pick_report_by_pick_id(pick_id) do
    # Sometimes we get multiple pick reports for the same pick, return the first one
    PickReport
    |> where([pr], pr.pick_id == ^pick_id)
    |> order_by([pr], pr.pick_id)
    |> limit(1)
    |> Repo.one()
    |> PickReport.preload_all()
  end

  def submit_pick(%Pick{} = pick) do
    pick
    |> Pick.submit_changeset()
    |> Repo.update()
  end

  def submit_pick!(%Pick{} = pick) do
    pick
    |> Pick.submit_changeset()
    |> Repo.update!()
  end

  def activate_pick(%Pick{} = pick, attrs) do
    pick
    |> Pick.activate_changeset(attrs)
    |> Repo.update()
  end

  def claim_change_pick(%Pick{} = pick) do
    Pick.claim_changeset(pick, %{})
  end

  def admin_claim_change_pick(%Pick{} = pick) do
    Pick.admin_claim_changeset(pick, %{})
  end

  def claim_pick(%Pick{} = pick, lead_picker, attrs \\ %{}) do
    pick
    |> Pick.claim_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:lead_picker, lead_picker)
    |> Ecto.Changeset.assoc_constraint(:lead_picker)
    |> Ecto.Changeset.change(status: :claimed)
    |> Repo.update()
  end

  def admin_claim_pick(%Pick{} = pick, lead_picker, attrs \\ %{}) do
    pick
    |> Pick.admin_claim_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:lead_picker, lead_picker)
    |> Ecto.Changeset.assoc_constraint(:lead_picker)
    |> Ecto.Changeset.change(status: :claimed)
    |> Repo.update()
  end

  def assign_lead_picker(%Pick{} = pick, attrs \\ %{}) do
    pick
    |> Pick.admin_assign_lead_picker_changeset(attrs)
    |> Ecto.Changeset.assoc_constraint(:lead_picker)
    |> Ecto.Changeset.change(status: :claimed)
    |> Repo.update()
  end

  def join_pick(%Pick{} = pick, %Person{} = picker) do
    if pick_has_spot?(pick) do
      if already_joined_pick?(pick, picker) do
        {:error, "You've already joined this pick."}
      else
        %PickPerson{}
        |> PickPerson.changeset(%{pick_id: pick.id, person_id: picker.id})
        |> Repo.insert!(returning: true)

        {:ok, pick}
      end
    else
      {:error, "Sorry, this pick is full."}
    end
  end

  def reschedule_change_pick(%Pick{} = pick) do
    Pick.reschedule_changeset(pick, %{})
  end

  def reschedule_pick(%Pick{} = pick, attrs \\ %{}) do
    pick_people = PickPerson |> where([pp], pp.pick_id == ^pick.id)
    reschedule_changeset = Pick.reschedule_changeset(pick, attrs)

    Multi.new()
    |> Multi.update(:pick, reschedule_changeset)
    |> Multi.delete_all(:pick_people, pick_people)
    |> Repo.transaction()
  end

  def leave_pick(%Pick{} = pick, %Person{} = picker) do
    if already_joined_pick?(pick, picker) do
      result =
        PickPerson
        |> where(pick_id: ^pick.id, person_id: ^picker.id)
        |> Repo.delete_all()

      if result == {1, nil} do
        {:ok, pick}
      else
        {:error, "There was an error leaving the pick."}
      end
    else
      {:error, "You can't leave a pick you haven't joined."}
    end
  end

  def cancel_pick(%Pick{} = pick, attrs \\ %{}) do
    if is_pick_cancelable?(pick) do
      pick
      |> Pick.cancel_changeset(attrs)
      |> Ecto.Changeset.change(
        status: :canceled
      )
      |> Repo.update()
    else
      {:error, "This pick cannot be cancelled"}
    end
  end

  def make_pick_private(%Pick{} = pick) do
    case pick.status == :scheduled and pick.is_private == false do
      false ->
        {:error, "Not able to make this pick private"}

      true ->
        pick
        |> Ecto.Changeset.change(is_private: true)
        |> Repo.update()
    end
  end

  def get_most_recent_snapshot(%Tree{} = tree) do
    TreeSnapshot
    |> where(tree_id: ^tree.id)
    |> last(:inserted_at)
    |> Repo.one()
  end

  def all_trees_updated?(%Pick{} = pick) do
    tree_count = Enum.count(pick.trees)

    trees_with_snapshots_count =
      pick.trees
      |> Enum.filter(fn tree -> Enum.all?(tree.snapshots, fn sp -> sp.id > 0 end) end)
      |> Enum.count()

    tree_count == trees_with_snapshots_count
  end

  def get_next_tree_without_update(%Pick{} = pick) do
    pick.trees
    |> Enum.reject(fn tree ->
      Enum.any?(pick.tree_snapshots, fn pts -> pts.tree_id == tree.id end)
    end)
    |> Enum.at(0)
  end

  def delete_pick!(%Pick{} = pick) do
    Repo.delete!(pick)
  end

  def count_this_week do
    today = Date.utc_today()
    week_start = Date.add(today, -Date.day_of_week(today))
    week_end = Date.add(week_start, 6)

    Pick
    |> where([p], p.status in ["claimed", "completed"])
    |> where([p], p.scheduled_date >= ^week_start)
    |> where([p], p.scheduled_date <= ^week_end)
    |> Repo.aggregate(:count, :id)
  end

  def count_this_season do
    this_year = Date.utc_today().year
    season_start = Date.from_erl!({this_year, 5, 1})
    season_end = Date.from_erl!({this_year, 12, 31})

    Pick
    |> where([p], p.status in ["claimed", "completed"])
    |> where([p], p.scheduled_date >= ^season_start)
    |> where([p], p.scheduled_date <= ^season_end)
    |> Repo.aggregate(:count, :id)
  end

  def count_picks_for_person_this_season(%Person{} = person) do
    this_year = Date.utc_today().year
    season_start = Date.from_erl!({this_year, 5, 1})
    season_end = Date.from_erl!({this_year, 12, 31})

    query =
      from(p in Pick,
        where: p.scheduled_date >= ^season_start,
        where: p.scheduled_date <= ^season_end,
        join: pp in PickPerson,
        on: pp.pick_id == p.id and pp.person_id == ^person.id,
        as: :pick_person,
        where: pp.person_id == ^person.id,

        # Exclude cancelled picks
        where: p.status != :canceled,

        # Some picks have multiple reports due to a UI bug
        distinct: true
      )
      |> exclude_busts()

    Repo.aggregate(query, :count, :id)
  end

  # Number of total pounds picked to indicate a bust
  @bust_threshold 5.0

  @doc """
  Joins pick report to `query`. Assumes the `query` is operating on `Pick`s.
  """
  def with_pick_report(query) do
    if has_named_binding?(query, :pick_report) do
      query
    else
      from p in query,
        left_join: pr in assoc(p, :report),
        as: :pick_report
    end
  end

  @doc """
  Joins PickFruit to `query`. Assumes the `query` is operating on `Pick`s.
  """
  def with_pick_fruits(query) do
    if has_named_binding?(query, :pick_fruits) do
      query
    else
      from [p, pick_report: pr] in with_pick_report(query),
        left_join: pf in assoc(pr, :fruits),
        as: :pick_fruits
    end
  end

  @doc """
  Exclude busts from a `query`. Assumes the query is operating on `Pick`s.
  """
  def exclude_busts(query) do
    from [p, pick_report: pr, pick_fruits: pf] in with_pick_fruits(query),
      where:
        not (fragment("? + ?", p.scheduled_date, p.scheduled_start_time) < ^DateTime.utc_now() and
               (pf.total_pounds_picked < @bust_threshold or is_nil(pr.id)))
  end

  def count_picks_for_tree_owner_total(tree_owner_id) when is_integer(tree_owner_id) do
    count =
      Pick
      |> where([p], p.requester_id == ^tree_owner_id)
      |> Repo.aggregate(:count, :id)

    count
  end

  def count_picks_for_tree_owner_this_season(tree_owner_id) when is_integer(tree_owner_id) do
    this_year = Date.utc_today().year
    season_start = Date.from_erl!({this_year, 5, 1})
    season_end = Date.from_erl!({this_year, 12, 31})

    count =
      Pick
      |> where([p], p.scheduled_date >= ^season_start)
      |> where([p], p.scheduled_date <= ^season_end)
      |> where([p], p.requester_id == ^tree_owner_id)
      |> Repo.aggregate(:count, :id)

    count
  end

  def tree_owner_has_requested_pick?(person_id) when is_integer(person_id) do
    count_picks_for_tree_owner_total(person_id) > 0
  end

  def person_has_picks_this_season?(%Person{} = person) do
    count_picks_for_person_this_season(person) > 0
  end

  def person_has_more_picks_than_waitlist_threshold(%Person{} = person) do
    count_picks_for_person_this_season(person) >= person.number_picks_trigger_waitlist
  end

  def requires_wait(%Pick{} = pick, %Person{} = person) do
    pick_start_datetime_with_timezone =
      pick.scheduled_date
      |> Timex.to_datetime("America/Toronto")
      |> Timex.set(time: pick.scheduled_start_time)

    now = Timex.now("America/Toronto")

    pick_not_last_minute =
      Timex.diff(pick_start_datetime_with_timezone, now, :hours) >= pick.last_minute_window_hours

    too_many_picks = Activities.person_has_more_picks_than_waitlist_threshold(person)

    has_joined_pick =
      PickPerson
      |> where([pp], pp.pick_id == ^pick.id and pp.person_id == ^person.id)
      |> Repo.exists?()

    is_pick_leader =
      Pick
      |> where([p], p.id == ^pick.id and p.lead_picker_id == ^person.id)
      |> Repo.exists?()

    is_admin = Person.is_admin(person)

    too_many_picks and pick_not_last_minute and not has_joined_pick and not is_pick_leader and
      not is_admin
  end

  def get_pick_report!(pick_id) do
    PickReport
    |> Repo.get_by!(pick_id: pick_id)
    |> PickReport.preload_all()
  end

  def get_pick_fruits(pick_id) do
    PickFruit
    |> where([pf], pf.pick_id == ^pick_id)
    |> Repo.all()
    |> PickFruit.preload_agencies()
  end

  def get_season_years() do
    query =
      from(p in Pick,
        select: fragment("EXTRACT(YEAR from ?)::integer", p.scheduled_date),
        where: not is_nil(p.scheduled_date),
        distinct: true
      )

    Repo.all(query)
  end

  def get_picker_information_and_attendance(year) do
    year_int = String.to_integer(year)

    attended =
      Person
      |> join(:left, [p], pa in PickAttendance, on: p.id == pa.person_id)
      |> where(
        [p, pa],
        fragment("EXTRACT(YEAR from ?)::integer", pa.inserted_at) == ^year_int
      )
      |> where([p, pa], pa.did_attend == true)
      |> group_by([p, pa], p.id)
      |> select([p, pa], %{
        id: p.id,
        first_name: p.first_name,
        last_name: p.last_name,
        is_picker: p.is_picker,
        is_leader_picker: p.is_lead_picker,
        is_tree_owner: p.is_tree_owner,
        is_active: p.membership_is_active,
        email: p.email,
        attended: count(p.id)
      })

    led =
      Pick
      |> where([p], fragment("EXTRACT(YEAR from ?)::integer", p.scheduled_date) == ^year_int)
      |> where([p], p.status == "completed")
      |> group_by([p], p.lead_picker_id)
      |> select([p], %{
        id: p.lead_picker_id,
        led: count(p.lead_picker_id)
      })

    Person
    |> join(:left, [p], a in subquery(attended), on: p.id == a.id)
    |> join(:left, [p, a], l in subquery(led), on: p.id == l.id)
    |> where([p, pa], p.is_picker == true or p.is_lead_picker == true)
    |> select([p, a, l], %{
      first_name: p.first_name,
      last_name: p.last_name,
      role:
        fragment(
          "(CASE WHEN ? THEN 'Picker, Lead Picker'
            WHEN ? THEN 'Picker'
            WHEN ? THEN 'Lead Picker'
            ELSE ''
          END) ||
          (CASE WHEN ? THEN ', ' ELSE '' END) ||
          (CASE WHEN ? THEN 'Admin' ELSE '' END) ||
          (CASE WHEN ? THEN ', ' ELSE '' END) ||
          (CASE WHEN ? THEN 'Tree Owner' ELSE '' END)
          ",
          p.is_picker and p.is_lead_picker,
          p.is_picker,
          p.is_lead_picker,
          (p.is_picker or p.is_lead_picker) and p.role == "admin",
          p.role == "admin",
          (p.is_picker or p.is_lead_picker) and p.is_tree_owner,
          p.is_tree_owner
        ),
      is_active: p.membership_is_active,
      email: p.email,
      attended: a.attended,
      led: l.led
    })
    |> Repo.stream()
  end

  def get_total_pick_fruit_weight(%Pick{} = pick) do
    PickFruit
    |> where([pf], pf.pick_id == ^pick.id)
    |> select([pf], pf.total_pounds_donated)
    |> Repo.all()
    |> Enum.sum()
  end

  defp validate_tree_count(changeset, current_trees) do
    new_trees = get_new_trees(changeset)
    replace_trees = get_replace_trees(changeset)

    cond do
      changeset.valid? == false ->
        changeset

      length(new_trees) > 0 ->
        changeset

      length(current_trees) == length(replace_trees) ->
        Ecto.Changeset.add_error(changeset, :trees, "You must pick at least one tree.")

      length(current_trees) > 0 ->
        changeset

      true ->
        Ecto.Changeset.add_error(changeset, :trees, "You must pick at least one tree.")
    end
  end

  defp get_new_trees(changeset) do
    if changeset.changes && changeset.changes[:trees] do
      Enum.reject(changeset.changes.trees, fn t -> t.action == :replace end)
    else
      []
    end
  end

  defp get_replace_trees(changeset) do
    if changeset.changes && changeset.changes[:trees] do
      Enum.filter(changeset.changes.trees, fn t -> t.action == :replace end)
    else
      []
    end
  end

  defp pick_has_spot?(%Pick{} = pick) do
    length(pick.pickers) < pick.volunteers_max
  end

  defp already_joined_pick?(%Pick{} = pick, %Person{} = picker) do
    Enum.member?(Enum.map(pick.pickers, fn p -> p.id end), picker.id)
  end

  defp is_pick_cancelable?(%Pick{} = pick) do
    Enum.member?([:submitted, :scheduled, :claimed, :rescheduled], pick.status)
  end

  defp sort_picks_query(query, field, desc) do
    cond do
      field not in [
        "id",
        "address",
        "lead_picker",
        "requester",
        "closest_intersection",
        "scheduled_date",
        "start_date",
        "end_date",
        "reason_for_cancellation",
        "report_submitted",
        "tree_type"
      ] ->
        order_by(query, desc: :updated_at)

      field == "closest_intersection" ->
        query =
          query
          |> join(:left, [pick], req in assoc(pick, :requester), as: :req)
          |> join(:left, [pick, req: req], property in assoc(req, :property), as: :prop)

        if desc == "true" do
          order_by(
            query,
            [pick, req: req, prop: property],
            desc: property.address_closest_intersection
          )
        else
          order_by(
            query,
            [pick, req: req, prop: property],
            asc: property.address_closest_intersection
          )
        end

      field == "address" ->
        query =
          query
          |> join(:left, [pick], req in assoc(pick, :requester), as: :req)
          |> join(:left, [pick, req: req], property in assoc(req, :property), as: :prop)

        if desc == "true" do
          order_by(
            query,
            [pick, req: req, prop: property],
            desc: property.address_street
          )
        else
          order_by(
            query,
            [pick, req: req, prop: property],
            asc: property.address_street
          )
        end

      field == "requester" ->
        query =
          query
          |> join(:left, [pick], req in assoc(pick, :requester), as: :req)
          |> group_by([pick, req: req], [pick.id, req.last_name, req.first_name])

        if desc == "true" do
          order_by(
            query,
            [pick, req: req],
            desc: [req.last_name, req.first_name]
          )
        else
          order_by(
            query,
            [pick, req: req],
            asc: [req.last_name, req.first_name]
          )
        end

      field == "lead_picker" ->
        query =
          query
          |> join(:left, [pick], lp in assoc(pick, :lead_picker), as: :lead_picker)
          |> group_by([pick, lead_picker: lp], [pick.id, lp.last_name, lp.first_name])

        if desc == "true" do
          order_by(
            query,
            [pick, lead_picker: lp],
            desc: [lp.last_name, lp.first_name]
          )
        else
          order_by(
            query,
            [pick, lead_picker: lp],
            asc: [lp.last_name, lp.first_name]
          )
        end

      field == "tree_type" ->
        query =
          query
          |> join(:inner, [pick], pt in PickTree, on: pick.id == pt.pick_id)
          |> join(:inner, [pick, pt], t in Tree, on: pt.tree_id == t.id)
          |> group_by([pick, pt, t], [pick.id, t.type])

        if desc == "true" do
          order_by(
            query,
            [pick, pt, t],
            desc: [t.type]
          )
        else
          order_by(
            query,
            [pick, pt, t],
            asc: [t.type]
          )
        end

      field == "report_submitted" ->
        query =
          query
          |> join(:left, [pick], report in assoc(pick, :report), as: :report)
          |> group_by([pick, report: report], [report.is_complete, report.has_issues_on_site])

        if desc == "true" do
          order_by(
            query,
            [pick, report: report],
            desc: [report.is_complete, report.has_issues_on_site]
          )
        else
          order_by(
            query,
            [pick, report: report],
            asc: [report.is_complete, report.has_issues_on_site]
          )
        end

      desc == "true" ->
        order_by(query, desc: ^String.to_existing_atom(field))

      true ->
        order_by(query, asc: ^String.to_existing_atom(field))
    end
  end
end
