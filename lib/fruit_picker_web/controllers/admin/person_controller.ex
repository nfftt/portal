defmodule FruitPickerWeb.Admin.PersonController do
  use FruitPickerWeb, :controller

  alias FruitPicker.{Accounts, Repo, Stats}
  alias FruitPicker.Accounts.{Person, Profile}
  alias FruitPicker.Partners.Agency
  alias FruitPickerWeb.Policies

  alias FruitPicker.Activities.{
    Pick,
    PickPerson,
    PickFruit
  }

  import Ecto.Query, warn: false

  plug(Policies, :is_admin)

  def index(conn, %{"type" => "pickers"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Accounts.list_pickers(page_num, sort_by, desc)
    total_stats = Stats.picker_total_stats(page.entries)
    season_stats = Stats.picker_season_stats(page.entries)

    render(conn, "index.html",
      people: page.entries,
      total_stats: total_stats,
      season_stats: season_stats,
      page: page,
      people_count: page.total_entries,
      people_slug: "pickers",
      people_type: "pickers",
      sort_by: sort_by,
      desc: desc
    )
  end

  def index(conn, %{"type" => "lead_pickers"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Accounts.list_lead_pickers(page_num, sort_by, desc)

    total_stats = Stats.lead_picker_total_stats(page.entries)
    season_stats = Stats.lead_picker_season_stats(page.entries)

    render(conn, "index.html",
      people: page.entries,
      total_stats: total_stats,
      season_stats: season_stats,
      page: page,
      people_count: page.total_entries,
      people_slug: "lead_pickers",
      people_type: "lead pickers",
      sort_by: sort_by,
      desc: desc
    )
  end

  def index(conn, %{"type" => "tree_owners"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Accounts.list_tree_owners(page_num, sort_by, desc)

    total_stats = Stats.tree_owner_total_stats(page.entries)
    season_stats = Stats.tree_owner_season_stats(page.entries)

    render(conn, "index.html",
      people: page.entries,
      total_stats: total_stats,
      season_stats: season_stats,
      page: page,
      people_count: page.total_entries,
      people_slug: "tree_owners",
      people_type: "tree owners",
      sort_by: sort_by,
      desc: desc
    )
  end

  def index(conn, %{"type" => "agency_partners"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Accounts.list_agencies(page_num, sort_by, desc)

    total_stats = Stats.agency_total_stats(page.entries)
    season_stats = Stats.agency_season_stats(page.entries)

    render(conn, "index.html",
      people: page.entries,
      total_stats: total_stats,
      season_stats: season_stats,
      page: page,
      people_count: page.total_entries,
      people_slug: "agency_partners",
      people_type: "agency partners",
      sort_by: sort_by,
      desc: desc
    )
  end

  def index(conn, %{"type" => "users"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Accounts.list_people(page_num, sort_by, desc)

    total_stats = Stats.picker_total_stats(page.entries)
    season_stats = Stats.picker_season_stats(page.entries)

    render(conn, "index.html",
      page: page,
      people: page.entries,
      total_stats: total_stats,
      season_stats: season_stats,
      people_count: page.total_entries,
      people_slug: "users",
      people_type: "users",
      sort_by: sort_by,
      desc: desc
    )
  end

  def index(conn, _params) do
    redirect(conn, to: Routes.admin_person_path(conn, :index, type: "users"))
  end

  def new(conn, %{"account_type" => account_type}) do
    profile_changeset = Accounts.change_profile(%Profile{})
    person_changeset = Accounts.change_person(%Person{profile: profile_changeset})

    render(
      conn,
      "register.html",
      changeset: person_changeset,
      account_type: account_type,
      action_name: "Register"
    )
  end

  def new(conn, _params) do
    changeset = Accounts.change_person(%Person{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"account_type" => account_type, "person" => person_params}) do
    case Accounts.admin_create_person(person_params, account_type) do
      {:ok, person} ->
        conn
        |> put_flash(
          :success,
          "The User " <>
            person.first_name <> " " <> person.last_name <> " was created successfully."
        )
        |> redirect(to: Routes.admin_person_path(conn, :show, person))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the user.")
        |> render(
          "register.html",
          changeset: changeset,
          account_type: account_type,
          action_name: "Register"
        )
    end
  end

  def show(conn, %{"id" => id}) do
    person = Accounts.get_person!(id)
    # TODO: handle case where there is no profile?
    render(conn, "show.html", person: person)
  end

  def stats(conn, %{"id" => id}) do
    person = Accounts.get_person!(id)

    case stats_type(person) do
      :admin ->
        admin_stats(conn, person)

      :agency ->
        agency_stats(conn, person)

      :tree_owner ->
        tree_owner_stats(conn, person)

      :lead_picker ->
        lead_picker_stats(conn, person)

      :picker ->
        picker_stats(conn, person)
    end
  end

  defp lead_picker_stats(conn, %Person{} = person) do
    missed_picks_count = Stats.get_missed_picks_count(person)
    season_stats = Stats.lead_picker_season_stats(person)
    total_stats = Stats.lead_picker_total_stats(person)

    completed_picks =
      Pick
      |> join(:left, [pick], pp in PickPerson,
        on: pp.pick_id == pick.id and pp.person_id == ^person.id
      )
      |> where([pick, _], pick.lead_picker_id == ^person.id and pick.status == "completed")
      |> or_where([pick, pp], pp.person_id == ^person.id and pick.status == "completed")
      |> join(:left, [pick, _], report in assoc(pick, :report))
      |> join(:left, [pick, _, report], trees in assoc(pick, :trees))
      |> join(:left, [pick, _, report, trees], lead_picker in assoc(pick, :lead_picker))
      |> join(:left, [pick, _, report, trees, lead_picker], fruit in PickFruit,
        on: fruit.pick_id == pick.id
      )
      |> group_by([pick, _, report, trees, lead_picker, fruit], [
        pick.id,
        report.id,
        trees.id,
        lead_picker.id
      ])
      |> preload([pick, _, report, trees, lead_picker, fruit],
        report: report,
        trees: trees,
        lead_picker: lead_picker
      )
      |> order_by([pick], desc: pick.scheduled_date)
      |> select([pick, _, report, trees, lead_picker, fruit], %{
        pick: pick,
        pounds_picked: sum(fruit.total_pounds_picked)
      })
      |> Repo.all()

    render(conn, "stats_lead_picker.html",
      person: person,
      season_stats: season_stats,
      total_stats: total_stats,
      missed_picks_count: missed_picks_count,
      completed_picks: completed_picks
    )
  end

  defp picker_stats(conn, %Person{} = person) do
    missed_picks_count = Stats.get_missed_picks_count(person)
    season_stats = Stats.picker_season_stats(person)
    total_stats = Stats.picker_total_stats(person)

    completed_picks =
      Pick
      |> join(:left, [pick], pp in PickPerson,
        on: pp.pick_id == pick.id and pp.person_id == ^person.id
      )
      |> where([pick, pp], pp.person_id == ^person.id and pick.status == "completed")
      |> join(:left, [pick, _], report in assoc(pick, :report))
      |> join(:left, [pick, _, report], trees in assoc(pick, :trees))
      |> join(:left, [pick, _, report, trees], lead_picker in assoc(pick, :lead_picker))
      |> join(:left, [pick, _, report, trees, lead_picker], fruit in PickFruit,
        on: fruit.pick_id == pick.id
      )
      |> group_by([pick, _, report, trees, lead_picker, fruit], [
        pick.id,
        report.id,
        trees.id,
        lead_picker.id
      ])
      |> preload([pick, _, report, trees, lead_picker, fruit],
        report: report,
        trees: trees,
        lead_picker: lead_picker
      )
      |> order_by([pick], desc: pick.scheduled_date)
      |> select([pick, _, report, trees, lead_picker, fruit], %{
        pick: pick,
        pounds_picked: sum(fruit.total_pounds_picked)
      })
      |> Repo.all()

    render(conn, "stats_picker.html",
      person: person,
      season_stats: season_stats,
      total_stats: total_stats,
      missed_picks_count: missed_picks_count,
      completed_picks: completed_picks
    )
  end

  defp admin_stats(conn, %Person{} = person) do
    season_stats = Stats.lead_picker_season_stats(person)
    total_stats = Stats.lead_picker_total_stats(person)

    completed_picks =
      Pick
      |> join(:left, [pick], pp in PickPerson,
        on: pp.pick_id == pick.id and pp.person_id == ^person.id
      )
      |> where([pick, _], pick.lead_picker_id == ^person.id and pick.status == "completed")
      |> or_where([pick, pp], pp.person_id == ^person.id and pick.status == "completed")
      |> join(:left, [pick, _], report in assoc(pick, :report))
      |> join(:left, [pick, _, report], trees in assoc(pick, :trees))
      |> join(:left, [pick, _, report, trees], lead_picker in assoc(pick, :lead_picker))
      |> join(:left, [pick, _, report, trees, lead_picker], fruit in PickFruit,
        on: fruit.pick_id == pick.id
      )
      |> group_by([pick, _, report, trees, lead_picker, fruit], [
        pick.id,
        report.id,
        trees.id,
        lead_picker.id
      ])
      |> preload([pick, _, report, trees, lead_picker, fruit],
        report: report,
        trees: trees,
        lead_picker: lead_picker
      )
      |> order_by([pick], desc: pick.scheduled_date)
      |> select([pick, _, report, trees, lead_picker, fruit], %{
        pick: pick,
        pounds_picked: sum(fruit.total_pounds_picked)
      })
      |> Repo.all()

    render(conn, "stats_admin.html",
      person: person,
      season_stats: season_stats,
      total_stats: total_stats,
      completed_picks: completed_picks
    )
  end

  defp agency_stats(conn, %Person{} = person) do
    season_stats = Stats.agency_season_stats(person)
    total_stats = Stats.agency_total_stats(person)

    completed_picks =
      Pick
      |> join(:left, [pick], agency in Agency, on: agency.id == pick.agency_id)
      |> where([pick, agency], agency.partner_id == ^person.id and pick.status == "completed")
      |> join(:left, [pick, _], report in assoc(pick, :report))
      |> join(:left, [pick, _, report], trees in assoc(pick, :trees))
      |> join(:left, [pick, _, report, trees], lead_picker in assoc(pick, :lead_picker))
      |> join(:left, [pick, _, report, trees, lead_picker], fruit in PickFruit,
        on: fruit.pick_id == pick.id
      )
      |> group_by([pick, _, report, trees, lead_picker, fruit], [
        pick.id,
        report.id,
        trees.id,
        lead_picker.id
      ])
      |> preload([pick, _, report, trees, lead_picker, fruit],
        report: report,
        trees: trees,
        lead_picker: lead_picker
      )
      |> order_by([pick], desc: pick.scheduled_date)
      |> select([pick, _, report, trees, lead_picker, fruit], %{
        pick: pick,
        pounds_donated: sum(fruit.total_pounds_donated)
      })
      |> Repo.all()

    render(conn, "stats_agency.html",
      person: person,
      season_stats: season_stats,
      total_stats: total_stats,
      completed_picks: completed_picks
    )
  end

  defp tree_owner_stats(conn, %Person{} = person) do
    season_stats = Stats.tree_owner_season_stats(person)
    total_stats = Stats.tree_owner_total_stats(person)

    completed_picks =
      Pick
      |> where([pick], pick.requester_id == ^person.id and pick.status == "completed")
      |> join(:left, [pick], report in assoc(pick, :report))
      |> join(:left, [pick, report], trees in assoc(pick, :trees))
      |> join(:left, [pick, report, trees], lead_picker in assoc(pick, :lead_picker))
      |> join(:left, [pick, report, trees, lead_picker], fruit in PickFruit,
        on: fruit.pick_id == pick.id
      )
      |> group_by([pick, report, trees, lead_picker, fruit], [
        pick.id,
        report.id,
        trees.id,
        lead_picker.id
      ])
      |> preload([pick, report, trees, lead_picker, fruit],
        report: report,
        trees: trees,
        lead_picker: lead_picker
      )
      |> order_by([pick], desc: pick.scheduled_date)
      |> select([pick, report, trees, lead_picker, fruit], %{
        pick: pick,
        pounds_picked: sum(fruit.total_pounds_picked),
        pounds_donated: sum(fruit.total_pounds_donated)
      })
      |> Repo.all()

    render(conn, "stats_tree_owner.html",
      person: person,
      season_stats: season_stats,
      total_stats: total_stats,
      completed_picks: completed_picks
    )
  end

  def edit(conn, %{"id" => id}) do
    person = Accounts.get_person!(id)
    changeset = Accounts.change_person(person)

    render(
      conn,
      "edit.html",
      person: person,
      changeset: changeset,
      action_name: "Update"
    )
  end

  def update(conn, %{"id" => id, "person" => person_params}) do
    person = Accounts.get_person!(id)

    case Accounts.update_person(person, person_params) do
      {:ok, person} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.admin_person_path(conn, :show, person))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "edit.html",
          person: person,
          changeset: changeset,
          action_name: "Update"
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    person = Accounts.get_person!(id)
    {:ok, _person} = Accounts.delete_person(person)

    conn
    |> put_flash(:info, "Person deleted successfully.")
    |> redirect(to: Routes.admin_person_path(conn, :index))
  end

  def deactivate(conn, %{"id" => id}) do
    person = Accounts.get_person!(id)
    {:ok, _person} = Accounts.deactivate_person(person)

    conn
    |> put_flash(:info, "Person deactivated successfully.")
    |> redirect(to: Routes.admin_person_path(conn, :index))
  end

  def export(conn, %{"type" => "lead_pickers"}) do
    lead_pickers = Accounts.list_lead_pickers()

    rows =
      for p <- lead_pickers do
        season_stats = Stats.lead_picker_season_stats(p)
        total_stats = Stats.lead_picker_total_stats(p)

        [
          p.id,
          p.first_name,
          p.last_name,
          FruitPickerWeb.Admin.PersonView.account_type(p),
          season_stats["picks_attended"],
          season_stats["picks_lead"],
          season_stats["pounds_picked"],
          season_stats["pounds_donated"],
          total_stats["picks_attended"],
          total_stats["picks_lead"],
          total_stats["pounds_picked"],
          total_stats["pounds_donated"]
        ]
      end

    csv_data =
      ([
         [
           "id",
           "first_name",
           "last_name",
           "role",
           "picks attended this season",
           "picks led this season",
           "pounds picked this season",
           "pounds donated this season",
           "total picks attended",
           "total picks led",
           "total pounds picked",
           "total pounds donated"
         ]
       ] ++ rows)
      |> CSV.encode()
      |> Enum.to_list()
      |> to_string()

    conn
    |> put_resp_header("content-disposition", "attachment;filename=lead_pickers.csv")
    |> put_resp_content_type("text/csv")
    |> send_resp(200, csv_data)
  end

  def available_with_current(person) do
    if person do
      [person | Partners.get_available()]
    else
      Partners.get_available()
    end
  end

  defp stats_type(%Person{} = person) do
    cond do
      person.role == :admin ->
        :admin

      person.role == :agency ->
        :agency

      person.role == :user and person.is_tree_owner ->
        :tree_owner

      person.role == :user and person.is_lead_picker ->
        :lead_picker

      person.role == :user and person.is_picker ->
        :picker

      # this is a user who is not a tree owner, lead picker, or picker -- most likely an ex admin who's account was downgraded.
      # Default to lead_picker stats
      true ->
        :lead_picker
    end
  end
end
