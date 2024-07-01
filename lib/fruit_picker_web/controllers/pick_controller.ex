defmodule FruitPickerWeb.PickController do
  @moduledoc false

  use FruitPickerWeb, :controller

  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.Person
  alias FruitPicker.Activities
  alias FruitPicker.Activities.Pick
  alias FruitPicker.Inventory
  alias FruitPicker.Partners
  alias FruitPicker.Mailer
  alias FruitPicker.Repo
  alias FruitPickerWeb.{Email, Policies, Resources}

  plug(
    Policies,
    :no_outstanding_reports
    when action in [:claim, :edit, :join, :leave, :request_claim, :request_join, :update]
  )

  def new(conn, _params) do
    trees = Accounts.get_persons_trees(conn.assigns.current_person)
    changeset = Activities.change_pick(%Pick{})

    if length(trees) > 0 do
      render(conn, "new.html",
        changeset: changeset,
        trees: trees
      )
    else
      conn
      |> put_flash(
        :error,
        "You must have at least one tree to request a pick. Please add a tree to your property first."
      )
      |> redirect(to: Routes.property_path(conn, :index))
    end
  end

  def create(conn, %{"pick" => pick_params}) do
    trees = fetch_trees(pick_params)
    my_trees = Accounts.get_persons_trees(conn.assigns.current_person)

    case Activities.create_pick(pick_params, conn.assigns.current_person, trees) do
      {:ok, pick} ->
        redirect(conn, to: Routes.pick_path(conn, :next_tree, pick, ["without_snapshot", "true"]))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem requesting the pick.")
        |> render("new.html",
          changeset: changeset,
          trees: my_trees
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    pick = Activities.get_pick!(id)
    trees = Accounts.get_persons_trees(conn.assigns.current_person)
    changeset = Activities.change_pick(pick)

    if pick.status in [:submitted, :rescheduled] do
      render(conn, "edit.html",
        pick: pick,
        changeset: changeset,
        trees: trees
      )
    else
      conn
      |> put_flash(:info, "Sorry, you can't edit a pick once it has been scheduled.")
      |> redirect(to: Routes.pick_path(conn, :show, pick))
    end
  end

  def update(conn, %{"id" => id, "pick" => pick_params}) do
    trees = fetch_trees(pick_params)
    pick = Activities.get_pick!(id)
    my_trees = Accounts.get_persons_trees(conn.assigns.current_person)

    if pick.status in [:submitted, :rescheduled] do
      case Activities.update_pick(pick, trees, pick_params) do
        {:ok, pick} ->
          redirect(conn,
            to: Routes.pick_path(conn, :next_tree, pick, ["without_snapshot", "true"])
          )

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_flash(:error, "There was a problem requesting the pick.")
          |> render("edit.html",
            changeset: changeset,
            pick: pick,
            trees: my_trees
          )
      end
    else
      conn
      |> put_flash(:info, "Sorry, you can't edit a pick once it has been scheduled.")
      |> redirect(to: Routes.pick_path(conn, :show, pick))
    end
  end

  def show(conn, %{"id" => id}) do
    pick = Resources.load!(conn, :pick)
    person = conn.assigns.current_person
    person_season_pick_count = Activities.count_picks_for_person_this_season(person)
    requires_wait = Activities.requires_wait(pick, person)

    render(conn, "show.html",
      pick: pick,
      person_season_pick_count: person_season_pick_count,
      requires_wait: requires_wait
    )
  end

  def index(conn, %{"type" => "all"} = params) do
    page_num = Map.get(params, "page", "1")
    page = Activities.list_picks(page_num)

    render(conn, "index.html",
      page: page,
      picks: page.entries,
      pick_count: page.total_entries,
      pick_type: "all",
      pick_title: "All Picks"
    )
  end

  def index(conn, _params) do
    redirect(conn, to: Routes.pick_path(conn, :index, type: "all"))
  end

  def tree_info(conn, %{"pick_id" => pick_id, "tree_id" => tree_id}) do
    pick = Activities.get_pick!(pick_id)
    tree = Accounts.get_tree!(tree_id)
    snapshot = Activities.get_most_recent_snapshot(tree)
    changeset = Accounts.change_tree_snapshot(snapshot, tree)

    render(conn, "tree_update.html",
      pick: pick,
      tree: tree,
      changeset: changeset
    )
  end

  def next_tree(conn, %{"pick_id" => pick_id, "without_snapshot" => "true"}) do
    pick = Activities.get_pick!(pick_id)
    next_tree = Activities.get_next_tree_without_update(pick)

    if next_tree == nil do
      redirect(conn, to: Routes.pick_path(conn, :confirm_details, pick))
    else
      redirect(conn, to: Routes.pick_path(conn, :tree_info, pick, next_tree))
    end
  end

  def next_tree(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    next_tree = Enum.at(pick.trees, 0)

    redirect(conn, to: Routes.pick_path(conn, :tree_info, pick, next_tree))
  end

  def tree_update(conn, %{
        "tree_snapshot" => tree_snapshot_params,
        "pick_id" => pick_id,
        "tree_id" => tree_id
      }) do
    pick = Activities.get_pick!(pick_id)
    tree = Accounts.get_tree!(tree_id)

    with {:ok, tree} <- Accounts.get_my_tree(tree.id, conn.assigns.current_person),
         {:ok, tree_snapshot} <- Accounts.create_tree_snapshot(tree, pick, tree_snapshot_params) do
      redirect(conn, to: Routes.pick_path(conn, :next_tree, pick, without_snapshot: "true"))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        my_trees = Accounts.get_persons_trees(conn.assigns.current_person)

        conn
        |> put_flash(:error, "There was a problem requesting the pick.")
        |> render("new.html",
          changeset: changeset,
          trees: my_trees
        )

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.pick_path(conn, :index))
    end
  end

  def confirm_details(conn, %{"pick_id" => pick_id}) do
    person = conn.assigns.current_person
    pick = Activities.get_pick!(pick_id)
    changeset = Accounts.change_person(person)

    render(conn, "profile_update.html",
      pick: pick,
      changeset: changeset
    )
  end

  def update_details(conn, %{"pick_id" => pick_id, "person" => person_params}) do
    pick = Activities.get_pick!(pick_id)
    person = conn.assigns.current_person

    case Accounts.update_person(person, person_params) do
      {:ok, person} ->
        case Activities.submit_pick(pick) do
          {:ok, _pick} ->
            email_requester_confirmation(pick)
            email_admins_new_pick(pick)
            redirect(conn, to: Routes.pick_path(conn, :thank_you, pick))

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_flash(:error, "There was a problem submitting the pick. Please try again.")
            |> redirect(to: Routes.pick_path(conn, :next_tree, pick))
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem confirming your details.")
        |> render("profile_update.html",
          pick: pick,
          changeset: changeset
        )
    end
  end

  def thank_you(conn, %{"pick_id" => pick_id}) do
    render(conn, "thank_you.html")
  end

  def request_reschedule(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    changeset = Activities.reschedule_change_pick(pick)

    # check that the pick is canceled
    if pick.status == :canceled and pick.requester.id == conn.assigns.current_person.id do
      render(conn, "reschedule.html",
        pick: pick,
        changeset: changeset
      )
    else
      conn
      |> put_flash(:error, "This pick isn't available to be rescheduled. Please cancel it first.")
      |> redirect(to: Routes.pick_path(conn, :show, pick))
    end
  end

  def reschedule(conn, %{"pick_id" => pick_id, "pick" => pick_params}) do
    pick = Activities.get_pick!(pick_id)

    if pick.status == :canceled and pick.requester.id == conn.assigns.current_person.id do
      case Activities.reschedule_pick(pick, pick_params) do
        {:ok, %{pick: pick}} ->
          conn
          |> put_flash(:info, "You reshceduled the pick.")
          |> redirect(to: Routes.pick_path(conn, :show, pick))

        {:error, :pick, %Ecto.Changeset{} = changeset, _changes} ->
          conn
          |> put_flash(:error, "There was a problem reshceduling the pick.")
          |> render("reschedule.html",
            changeset: changeset,
            pick: pick
          )
      end
    else
      conn
      |> put_flash(:error, "This pick isn't available to be rescheduled. Please cancel it first.")
      |> redirect(to: Routes.pick_path(conn, :show, pick))
    end
  end

  def request_cancel(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    changeset = Pick.cancel_changeset(pick, %{})

    render(conn, "cancel.html",
      pick: pick,
      changeset: changeset
    )
  end

  def cancel(conn, %{"pick_id" => pick_id, "pick" => pick_params}) do
    me = conn.assigns.current_person
    pick = Activities.get_pick!(pick_id) |> Repo.preload(requester: :profile)
    changeset = Pick.cancel_changeset(pick, pick_params)

    case Activities.cancel_pick(pick, pick_params) do
      {:ok, updated_pick} ->
        email_admins_pick_cancelation(pick, me, updated_pick.reason_for_cancellation)
        email_pickers_pick_cancelation(pick)

        if pick.lead_picker_id == me.id do
          email_tree_owner_cancelation(pick)
        end

        if not is_nil(pick.lead_picker) and pick.requester_id == me.id do
          email_lead_picker_pick_cancelation(pick, updated_pick.reason_for_cancellation)
        end

        unless is_nil(pick.agency) do
          email_agency_pick_cancelation(pick)
        end

        if should_reschedule(updated_pick) do
          conn
          |> put_flash(:info, "The pick has been canceled, please reschedule it now")
          |> redirect(to: Routes.pick_path(conn, :request_reschedule, updated_pick))
        else
          conn
          |> put_flash(:info, "The pick has been canceled")
          |> redirect(to: Routes.pick_path(conn, :show, updated_pick))
        end

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
        |> redirect(to: Routes.pick_path(conn, :show, pick))
    end
  end

  def request_claim(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    agencies = Partners.list_agencies_accepting_fruit()
    equipment_sets = Inventory.list_equipment_sets(:active)
    changeset = Activities.claim_change_pick(pick)

    # check that the pick isn't already claimed
    if is_nil(pick.lead_picker_id) and pick.status == :scheduled do
      render(conn, "claim.html",
        changeset: changeset,
        agencies: agencies,
        equipment_sets: equipment_sets,
        pick: pick
      )
    else
      conn
      |> put_flash(:error, "This pick isn't available to be claimed.")
      |> redirect(to: Routes.pick_path(conn, :show, pick))
    end
  end

  def claim(conn, %{"pick_id" => pick_id, "pick" => pick_params}) do
    pick = Activities.get_pick!(pick_id)
    me = conn.assigns.current_person

    if is_nil(pick.lead_picker) do
      case Activities.claim_pick(pick, me, pick_params) do
        {:ok, pick} ->
          pick = Activities.get_pick!(pick.id)
          email_home_owner_pick_is_scheduled(pick)
          email_agency_pick_is_scheduled(pick)

          conn
          |> put_flash(:info, "You claimed the pick.")
          |> redirect(to: Routes.pick_path(conn, :show, pick))

        {:error, %Ecto.Changeset{} = changeset} ->
          agencies = Partners.list_agencies_accepting_fruit()
          equipment_sets = Inventory.list_equipment_sets(:active)

          conn
          |> put_flash(:error, "There was a problem claiming the pick.")
          |> render("claim.html",
            changeset: changeset,
            agencies: agencies,
            equipment_sets: equipment_sets,
            pick: pick
          )
      end
    else
      conn
      |> put_flash(:error, "Sorry, this pick has already been claimed.")
      |> render("show.html",
        pick: pick
      )
    end
  end

  def request_join(conn, %{"pick_id" => pick_id}) do
    person = conn.assigns.current_person
    person_id = conn.assigns.current_person.id
    pick = Activities.get_pick!(pick_id)
    picker_ids = Enum.map(pick.pickers, fn p -> p.id end)

    cond do
      length(pick.pickers) >= pick.volunteers_max ->
        conn
        |> put_flash(:info, "Sorry, this pick is full.")
        |> redirect(to: Routes.pick_path(conn, :show, pick))

      person_id == pick.lead_picker_id ->
        conn
        |> put_flash(:info, "Sorry, you cannot join a pick you are leading.")
        |> redirect(to: Routes.pick_path(conn, :show, pick))

      is_nil(pick.lead_picker_id) ->
        conn
        |> put_flash(:info, "Sorry, you cannot join a pick that doesn't have a leader.")
        |> redirect(to: Routes.pick_path(conn, :show, pick))

      person_id in picker_ids ->
        conn
        |> put_flash(:info, "Sorry, you have already joined this pick.")
        |> redirect(to: Routes.pick_path(conn, :show, pick))

      Activities.requires_wait(pick, person) ->
        conn
        |> put_flash(
          :info,
          "Sorry, you have already been on a pick this season. Please wait for the last minute pick window."
        )
        |> redirect(to: Routes.pick_path(conn, :show, pick))

      true ->
        render(conn, "join.html", pick: pick)
    end
  end

  def join(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    me = conn.assigns.current_person

    case Activities.join_pick(pick, me) do
      {:ok, pick} ->
        conn
        |> put_flash(:info, "You joined the pick.")
        |> redirect(to: Routes.pick_path(conn, :show, pick))

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.pick_path(conn, :show, pick))
    end
  end

  def leave(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    me = conn.assigns.current_person

    case Activities.leave_pick(pick, me) do
      {:ok, _pick} ->
        conn
        |> put_flash(:info, "You have left the pick.")
        |> redirect(to: Routes.pick_path(conn, :show, pick))

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.pick_path(conn, :show, pick))
    end
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

  defp email_home_owner_pick_is_scheduled(%Pick{} = pick) do
    pick
    |> Email.home_owner_pick_is_scheduled()
    |> Mailer.deliver_later()
  end

  defp email_agency_pick_is_scheduled(%Pick{} = pick) do
    pick
    |> Email.agency_pick_is_scheduled(pick.agency)
    |> Mailer.deliver_later()
  end

  defp email_requester_confirmation(%Pick{} = pick) do
    Email.pick_request_confirmation(pick.requester, pick)
    |> Mailer.deliver_later()
  end

  defp email_admins_new_pick(%Pick{} = pick) do
    admins = Repo.all(Person.admins())

    Enum.each(admins, fn a ->
      a
      |> Email.admin_new_pick(pick)
      |> Mailer.deliver_later()
    end)
  end

  defp email_admins_pick_cancelation(%Pick{} = pick, canceler, reason) do
    admins = Repo.all(Person.admins())

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

  defp should_reschedule(%Pick{} = pick) do
    cond do
      pick.reason_for_cancellation == "I have a scheduling conflict and want to reschedule" ->
        true

      pick.reason_for_cancellation == "My fruit isn't ripe yet, I need to reschedule" ->
        true

      true ->
        false
    end
  end
end
