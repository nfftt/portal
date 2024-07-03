defmodule FruitPickerWeb.Admin.PickController do
  @moduledoc false

  use FruitPickerWeb, :controller

  import Ecto.Query, warn: false

  alias FruitPicker.{Mailer, Repo}
  alias FruitPicker.Accounts

  alias FruitPicker.Accounts.{
    Person,
    Tree,
    TreeSnapshot
  }

  alias FruitPicker.Activities

  alias FruitPicker.Activities.{
    Pick,
    PickAttendance,
    PickReport,
    PickPerson,
    PickFruit,
    PickFruitAgency
  }

  alias FruitPicker.Inventory
  alias FruitPicker.Partners
  alias FruitPickerWeb.Email

  def request_activate(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    changeset = Activities.change_pick(pick)

    render(conn, "activate.html",
      changeset: changeset,
      pick: pick
    )
  end

  def edit(conn, %{"id" => id}) do
    pick = Activities.get_pick!(id)
    trees = Accounts.get_persons_trees(pick.requester)
    agencies = Partners.list_agencies_accepting_fruit()
    equipment_sets = Inventory.list_equipment_sets(:active)
    changeset = Pick.admin_changeset(pick, %{})

    if pick.status == "completed" do
      conn
      |> put_flash(:error, "You cannot edit a completed pick.")
      |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
    else
      render(conn, "edit.html",
        pick: pick,
        changeset: changeset,
        agencies: agencies,
        equipment_sets: equipment_sets,
        trees: trees
      )
    end
  end

  def update(conn, %{"id" => id, "pick" => pick_params}) do
    trees = fetch_trees(pick_params)
    pick = Activities.get_pick!(id)
    requester_trees = Accounts.get_persons_trees(pick.requester)

    if pick.status == "completed" do
      conn
      |> put_flash(:error, "You cannot edit a completed pick.")
      |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
    else
      case Activities.admin_update_pick(pick, trees, pick_params) do
        {:ok, pick} ->
          conn
          |> put_flash(:success, "The pick has been updated.")
          |> redirect(to: Routes.admin_pick_path(conn, :show, pick))

        {:error, %Ecto.Changeset{} = changeset} ->
          pick = Activities.get_pick!(id)
          agencies = Partners.list_agencies_accepting_fruit()
          equipment_sets = Inventory.list_equipment_sets(:active)

          conn
          |> put_flash(:error, "There was a problem updating the pick.")
          |> render("edit.html",
            changeset: changeset,
            pick: pick,
            agencies: agencies,
            equipment_sets: equipment_sets,
            trees: requester_trees
          )
      end
    end
  end

  def activate(conn, %{"pick_id" => pick_id} = params) do
    pick = Activities.get_pick!(pick_id)
    type = Map.get(params, "type")

    pick_params = %{
      is_private: type == "private"
    }

    case Activities.activate_pick(pick, pick_params) do
      {:ok, pick} ->
        if pick.is_private do
          conn
          |> put_flash(:info, "The pick was made private.")
          |> redirect(to: Routes.admin_pick_path(conn, :request_claim, pick))
        else
          email_lead_pickers_new_pick(pick)

          conn
          |> put_flash(:info, "The pick was activated.")
          |> redirect(to: Routes.dashboard_path(conn, :index))
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem activating the pick.")
        |> render("activate.html",
          changeset: changeset,
          pick: pick
        )
    end
  end

  def show(conn, %{"id" => id}) do
    pick = Activities.get_pick!(id)

    render(conn, "show.html", pick: pick)
  end

  def index(conn, %{"type" => "incomplete"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Activities.list_picks_by_status("started", page_num, sort_by, desc)

    render(conn, "index.html",
      page: page,
      picks: page.entries,
      pick_count: page.total_entries,
      pick_type: "incomplete",
      sort_by: sort_by,
      desc: desc,
      pick_title: "Incompleted Pick Requests"
    )
  end

  def index(conn, %{"type" => "requested"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Activities.list_picks_by_status("submitted", page_num, sort_by, desc)

    render(conn, "index.html",
      page: page,
      picks: page.entries,
      pick_count: page.total_entries,
      pick_type: "requested",
      sort_by: sort_by,
      desc: desc,
      pick_title: "Pick Requests"
    )
  end

  def index(conn, %{"type" => "unclaimed"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Activities.list_picks_by_status("scheduled", page_num, sort_by, desc)

    render(conn, "index.html",
      page: page,
      picks: page.entries,
      pick_count: page.total_entries,
      pick_type: "unclaimed",
      sort_by: sort_by,
      desc: desc,
      pick_title: "Unclaimed Picks"
    )
  end

  def index(conn, %{"type" => "scheduled"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Activities.list_picks_by_status("claimed", page_num, sort_by, desc)

    render(conn, "index.html",
      page: page,
      picks: page.entries,
      pick_count: page.total_entries,
      pick_type: "scheduled",
      sort_by: sort_by,
      desc: desc,
      pick_title: "Scheduled Picks"
    )
  end

  def index(conn, %{"type" => "canceled"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Activities.list_picks_by_status("canceled", page_num, sort_by, desc)

    render(conn, "index.html",
      page: page,
      picks: page.entries,
      pick_count: page.total_entries,
      pick_type: "canceled",
      sort_by: sort_by,
      desc: desc,
      pick_title: "Canceled Picks"
    )
  end

  def index(conn, %{"type" => "rescheduled"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Activities.list_picks_by_status("rescheduled", page_num, sort_by, desc)

    render(conn, "index.html",
      page: page,
      picks: page.entries,
      pick_count: page.total_entries,
      pick_type: "rescheduled",
      sort_by: sort_by,
      desc: desc,
      pick_title: "Rescheduled Picks"
    )
  end

  def index(conn, %{"type" => "completed"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Activities.list_completed_picks(page_num, sort_by, desc)

    render(conn, "index.html",
      page: page,
      picks: page.entries,
      pick_count: page.total_entries,
      pick_type: "completed",
      sort_by: sort_by,
      desc: desc,
      pick_title: "Completed Picks"
    )
  end

  def index(conn, %{"type" => "all"} = params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Activities.list_picks(page_num, sort_by, desc)

    render(conn, "index.html",
      page: page,
      picks: page.entries,
      pick_count: page.total_entries,
      pick_type: "all",
      sort_by: sort_by,
      desc: desc,
      pick_title: "All Picks"
    )
  end

  def index(conn, _params) do
    redirect(conn, to: Routes.admin_pick_path(conn, :index, type: "all"))
  end

  def request_cancel(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    changeset = Pick.cancel_changeset(pick, %{})

    render(conn, "cancel.html",
      pick: pick,
      changeset: changeset
    )
  end

  def make_private(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)

    case Activities.make_pick_private(pick) do
      {:error, message} ->
        conn =
          conn
          |> put_flash(:error, message)
          |> redirect(to: Routes.admin_pick_path(conn, :show, pick))

      {:ok, new_pick} ->
        conn =
          conn
          |> put_flash(:info, "Made this pick private")
          |> redirect(to: Routes.admin_pick_path(conn, :show, new_pick))
    end
  end

  def assign_lead_picker(conn, %{"pick_id" => pick_id} = pick) do
    pick = Activities.get_pick!(pick_id)
    render(conn, "assign_lead_picker.html", pick: pick)
  end

  def cancel(conn, %{"pick_id" => pick_id, "pick" => pick_params}) do
    me = conn.assigns.current_person
    pick = Activities.get_pick!(pick_id) |> Repo.preload(requester: :profile)
    changeset = Pick.cancel_changeset(pick, pick_params)

    case Activities.cancel_pick(pick, pick_params) do
      {:ok, updated_pick} ->
        email_admins_pick_cancelation(pick, me, updated_pick.reason_for_cancellation)
        email_pickers_pick_cancelation(pick)

        unless is_nil(pick.agency) do
          email_agency_pick_cancelation(pick)
        end

        unless is_nil(pick.lead_picker) do
          email_lead_picker_pick_cancelation(pick, updated_pick.reason_for_cancellation)
        end

        email_tree_owner_cancelation(pick)

        conn
        |> put_flash(:info, "The pick has been canceled")
        |> redirect(to: Routes.admin_pick_path(conn, :show, pick))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem canceling the pick.")
        |> render("cancel.html",
          changeset: changeset,
          pick: pick
        )

      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> render("cancel.html",
          changeset: changeset,
          pick: pick
        )
    end
  end

  def request_reschedule(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    agencies = Partners.list_agencies_accepting_fruit()
    equipment_sets = Inventory.list_equipment_sets()
    changeset = Activities.reschedule_change_pick(pick)

    # check that the pick is canceled
    if pick.status != :completed do
      render(conn, "reschedule.html",
        pick: pick,
        agencies: agencies,
        equipment_sets: equipment_sets,
        changeset: changeset
      )
    else
      conn
      |> put_flash(:error, "This pick isn't available to be rescheduled.")
      |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
    end
  end

  def reschedule(conn, %{"pick_id" => pick_id, "pick" => pick_params}) do
    pick = Activities.get_pick!(pick_id)
    agencies = Partners.list_agencies()
    equipment_sets = Inventory.list_equipment_sets()

    case Activities.reschedule_pick(pick, pick_params) do
      {:ok, %{pick: pick}} ->
        conn
        |> put_flash(:info, "You reshceduled the pick.")
        |> redirect(to: Routes.admin_pick_path(conn, :show, pick))

      {:error, :pick, %Ecto.Changeset{} = changeset, _changes} ->
        conn
        |> put_flash(:error, "There was a problem reshceduling the pick.")
        |> render("reschedule.html",
          changeset: changeset,
          agencies: agencies,
          equipment_sets: equipment_sets,
          pick: pick
        )
    end
  end

  def request_claim(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    agencies = Partners.list_agencies_accepting_fruit()
    equipment_sets = Inventory.list_equipment_sets(:active)
    changeset = Activities.admin_claim_change_pick(pick)

    # check that the pick isn't already claimed
    if is_nil(pick.lead_picker_id) and pick.status in [:scheduled, :rescheduled] and
         pick.is_private do
      render(conn, "claim.html",
        changeset: changeset,
        agencies: agencies,
        equipment_sets: equipment_sets,
        pick: pick
      )
    else
      conn
      |> put_flash(:error, "This pick isn't available to be claimed.")
      |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
    end
  end

  def claim(conn, %{"pick_id" => pick_id, "pick" => pick_params}) do
    pick = Activities.get_pick!(pick_id)
    me = conn.assigns.current_person

    case Activities.admin_claim_pick(pick, me, pick_params) do
      {:ok, _pick} ->
        conn
        |> put_flash(:info, "You claimed the private pick.")
        |> redirect(to: Routes.admin_pick_path(conn, :show, pick))

      {:error, %Ecto.Changeset{} = changeset} ->
        agencies = Partners.list_agencies_accepting_fruit()
        equipment_sets = Inventory.list_equipment_sets(:active)

        conn
        |> put_flash(:error, "There was a problem claiming the private pick.")
        |> render("claim.html",
          changeset: changeset,
          agencies: agencies,
          equipment_sets: equipment_sets,
          pick: pick
        )
    end
  end

  def remove_lead_picker(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    person = Accounts.get_person!(pick.lead_picker_id)

    if pick.status == :completed do
      conn
      |> put_flash(:error, "You cannot remove someone from a completed pick.")
      |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
    else
      case Ecto.Changeset.change(pick, lead_picker_id: nil) |> Repo.update() do
        {:ok, _pick} ->
          email_lead_picker_about_removal(person, pick)

          conn
          |> put_flash(:info, "#{person.first_name} #{person.last_name} removed as pick leader.")
          |> redirect(to: Routes.admin_pick_path(conn, :show, pick))

        {:error, _} ->
          conn
          |> put_flash(
            :error,
            "There was an error removing #{person.first_name} #{person.last_name} as pick leader."
          )
          |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
      end
    end
  end

  def remove_picker(conn, %{"pick_id" => pick_id, "person_id" => person_id}) do
    person = Accounts.get_person!(person_id)
    pick = Activities.get_pick!(pick_id)

    if pick.status == :completed do
      conn
      |> put_flash(:error, "You cannot remove someone from a completed pick.")
      |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
    else
      pickers =
        Enum.reject(pick.pickers, fn picker ->
          picker.id == person.id
        end)

      case Pick.changeset(pick, %{})
           |> Ecto.Changeset.put_assoc(:pickers, pickers)
           |> Repo.update() do
        {:ok, _pick} ->
          email_picker_about_removal(person, pick)

          conn
          |> put_flash(:info, "#{person.first_name} #{person.last_name} removed from pick.")
          |> redirect(to: Routes.admin_pick_path(conn, :show, pick))

        {:error, _} ->
          conn
          |> put_flash(
            :error,
            "There was an error removing #{person.first_name} #{person.last_name} from pick."
          )
          |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
      end
    end
  end

  def delete(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    Activities.delete_pick!(pick)

    conn
    |> put_flash(:info, "Pick deleted successfully.")
    |> redirect(to: Routes.dashboard_path(conn, :index))
  end

  defp fetch_trees(pick_params) do
    if Map.has_key?(pick_params, "tree_ids") do
      pick_params["tree_ids"]
      |> Map.keys()
      |> Accounts.get_trees()
    else
      []
    end
  end

  def edit_pick_report(conn, %{"pick_id" => pick_id}) do
    render(conn, "edit_pick_report.html", pick_id: pick_id)
  end

  def edit_pick_attendance(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)

    pickers =
      Enum.map(pick.report.attendees, fn a ->
        PickAttendance.changeset(a, %{
          id: a.id,
          person_id: a.person_id,
          pick_report_id: a.pick_report_id,
          name: "#{a.person.first_name} #{a.person.last_name}"
        })
      end)

    changeset =
      PickReport.changeset(
        Map.merge(pick.report, %{attendees: pickers}),
        %{}
      )

    render(conn, "edit_pick_attendance.html", pick_id: pick_id, changeset: changeset)
  end

  def update_pick_attendance(conn, %{"pick_id" => pick_id, "pick_report" => pick_report}) do
    list = Map.to_list(pick_report["attendees"]) |> Enum.map(fn {k, v} -> v end)
    pick = Activities.get_pick!(pick_id)

    case Activities.update_attendees(list) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Attendees updated.")
        |> redirect(to: Routes.admin_pick_path(conn, :show, pick))

      {:error, _} ->
        conn
        |> put_flash(:error, "There was a problem updating attendees.")
        |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
    end
  end

  def edit_pick_fruits(conn, %{"pick_id" => pick_id}) do
    pick_report = Activities.get_pick_report_by_pick_id(pick_id)
    pick_fruits = Activities.get_pick_fruits(pick_id)
    pick = Activities.get_pick!(pick_id)

    changeset = PickReport.changeset(pick_report, %{})

    agencies =
      Partners.list_agencies_available_to_report(
        pick.scheduled_date,
        pick.scheduled_start_time
      )
      |> generate_options()

    render(conn, "edit_pick_fruits.html",
      pick_id: pick_id,
      changeset: changeset,
      agencies: agencies
    )
  end

  def update_pick_fruits(conn, %{"pick_id" => pick_id, "pick_report" => pick_report}) do
    pick = Activities.get_pick!(pick_id)

    case Activities.update_pick_fruits(pick_report, pick_id) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Fruits updated")
        |> redirect(to: Routes.admin_pick_path(conn, :show, pick))

      {:error, changeset} ->
        agencies =
          Partners.list_agencies_available_to_report(
            pick.scheduled_date,
            pick.scheduled_start_time
          )
          |> generate_options()

        conn
        |> put_flash(:error, "There was a problem updating fruits")
        |> render("edit_pick_fruits.html",
          pick_id: pick_id,
          changeset: changeset,
          agencies: agencies
        )
    end
  end

  defp email_lead_pickers_new_pick(%Pick{} = pick) do
    lead_pickers =
      Person.lead_pickers()
      |> Person.active()
      |> Repo.all()

    Enum.each(lead_pickers, fn lp ->
      lp
      |> Email.new_public_pick(pick)
      |> Mailer.deliver_later()
    end)
  end

  defp email_picker_about_removal(%Person{} = person, %Pick{} = pick) do
    person
    |> Email.picker_removed(pick)
    |> Mailer.deliver_later()
  end

  defp email_lead_picker_about_removal(%Person{} = person, %Pick{} = pick) do
    person
    |> Email.lead_picker_removed(pick)
    |> Mailer.deliver_later()
  end

  defp email_admins_pick_cancelation(%Pick{} = pick, canceler, reason) do
    admins =
      Person.admins()
      |> Person.active()
      |> Repo.all()

    Enum.each(admins, fn a ->
      a
      |> Email.pick_cancelation_admin(pick, canceler, reason)
      |> Mailer.deliver_later()
    end)
  end

  defp email_lead_picker_pick_cancelation(%Pick{} = pick, reason) do
    Email.pick_cancelation_lead_picker(pick.lead_picker, pick, reason)
    |> Mailer.deliver_later()
  end

  defp email_pickers_pick_cancelation(%Pick{} = pick) do
    Enum.each(pick.pickers, fn pk ->
      pk
      |> Email.pick_cancelation_picker(pick)
      |> Mailer.deliver_later()
    end)
  end

  defp email_agency_pick_cancelation(%Pick{} = pick) do
    Email.pick_cancelation_agency(pick.agency, pick)
    |> Mailer.deliver_later()
  end

  defp email_tree_owner_cancelation(%Pick{} = pick) do
    Email.pick_cancelation_tree_owner(pick.requester, pick)
    |> Mailer.deliver_later()
  end

  defp generate_options(list) do
    Enum.map(list, &{"#{&1.name} (#{&1.closest_intersection})", &1.id})
  end
end
