defmodule FruitPicker.Activities.Pick do
  @moduledoc """
  Data representation of picks in all of the stages from
  request to sumissions, scheduling and completion.
  """

  use FruitPicker.Schema

  import Ecto.Query, warn: false

  alias FruitPicker.Activities.{
    Pick,
    PickTree,
    PickPerson,
    PickReport
  }

  alias FruitPicker.Accounts.{
    Person,
    Tree,
    TreeSnapshot
  }

  alias FruitPicker.Inventory.EquipmentSet
  alias FruitPicker.Partners.Agency
  alias FruitPickerWeb.SharedView

  defenum(StatusEnum, :status, [
    :started,
    :submitted,
    # this means "activated"
    :scheduled,
    :claimed,
    :canceled,
    :rescheduled,
    :completed
  ])

  schema "picks" do
    field(:tree_owner_takes, :string)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:ladder_provided, :string)
    field(:notes, :string)

    field(:pick_time_any, :boolean)
    field(:pick_time_morning, :boolean)
    field(:pick_time_afternoon, :boolean)
    field(:pick_time_evening, :boolean)

    field(:scheduled_date, :date)
    field(:scheduled_start_time, :time)
    field(:scheduled_end_time, :time)

    field(:volunteers_min, :integer, default: 2)
    field(:volunteers_max, :integer, default: 5)

    field(:reason_for_cancellation, :string)

    field(:is_private, :boolean, default: false)

    field(:status, StatusEnum)

    field(:last_minute_window_hours, :integer, default: 5)

    many_to_many(:trees, Tree, join_through: PickTree, on_replace: :delete, on_delete: :delete_all)

    many_to_many(:pickers, Person,
      join_through: PickPerson,
      on_replace: :delete,
      on_delete: :delete_all
    )

    has_many(:tree_snapshots, TreeSnapshot, on_delete: :delete_all)
    has_one(:report, PickReport, on_delete: :delete_all)
    belongs_to(:requester, Person)
    belongs_to(:lead_picker, Person)
    belongs_to(:agency, Agency)
    belongs_to(:equipment_set, EquipmentSet)

    timestamps()
  end

  @doc false
  def changeset(pick, attrs) do
    pick
    |> cast(attrs, [
      :tree_owner_takes,
      :start_date,
      :end_date,
      :ladder_provided,
      :notes,
      :pick_time_any,
      :pick_time_morning,
      :pick_time_afternoon,
      :pick_time_evening
    ])
    |> validate_required([
      :tree_owner_takes,
      :start_date,
      :end_date,
      :ladder_provided,
      :pick_time_any,
      :pick_time_morning,
      :pick_time_afternoon,
      :pick_time_evening
    ])
    |> validate_length(:trees, min: 1)
    |> validate_pick_time()
    |> validate_dates()
  end

  @doc false
  def admin_changeset(pick, attrs) do
    attrs = set_end_time(attrs)

    pick
    |> cast(attrs, [
      :tree_owner_takes,
      :start_date,
      :end_date,
      :ladder_provided,
      :notes,
      :pick_time_any,
      :pick_time_morning,
      :pick_time_afternoon,
      :pick_time_evening,
      :scheduled_date,
      :scheduled_start_time,
      :scheduled_end_time,
      :equipment_set_id,
      :agency_id,
      :volunteers_max,
      :last_minute_window_hours
    ])
    |> validate_required([
      :tree_owner_takes,
      :start_date,
      :end_date,
      :ladder_provided,
      :pick_time_any,
      :pick_time_morning,
      :pick_time_afternoon,
      :pick_time_evening
    ])
    |> validate_length(:trees, min: 1)
    |> validate_inclusion(:last_minute_window_hours, 0..23,
      message: "is invalid, must be between 0 and 23"
    )
    |> validate_pick_time()
    |> validate_dates()
    |> validate_scheduled_date()
    |> validate_schedule_exists()
    |> validate_equipment_set_available()
    |> validate_agency_available()
  end

  defp validate_schedule_exists(changeset) do
    status = get_field(changeset, :status)

    if status in [:claimed, :rescheduled] do
      changeset
      |> validate_required([
        :scheduled_date,
        :scheduled_start_time,
        :scheduled_end_time,
        :equipment_set_id
      ])
    else
      changeset
    end
  end

  defp validate_dates(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    case valid_start_end_dates(start_date, end_date) do
      {:ok, _nothing} ->
        changeset

      {:error, message} ->
        add_error(changeset, :end_date, message)
    end
  end

  defp valid_start_end_dates(start_date, end_date) do
    cond do
      is_nil(start_date) || is_nil(end_date) ->
        {:ok, nil}

      Date.diff(end_date, start_date) > 4 ->
        {:error, "Please choose dates no more than 4 days apart."}

      Date.diff(end_date, start_date) < 0 ->
        {:error, "The end date must be after the start date."}

      true ->
        {:ok, nil}
    end
  end

  @doc false
  def submit_changeset(pick) do
    pick
    |> Ecto.Changeset.change(status: :submitted)
  end

  @doc false
  def activate_changeset(pick, attrs) do
    pick
    |> cast(attrs, [:is_private])
    |> validate_required([:is_private])
    |> Ecto.Changeset.change(status: :scheduled)
  end

  @doc false
  def claim_changeset(pick, attrs) do
    attrs = set_end_time(attrs)

    pick
    |> cast(attrs, [
      :scheduled_date,
      :scheduled_start_time,
      :scheduled_end_time,
      :equipment_set_id,
      :agency_id
    ])
    |> validate_required([
      :scheduled_date,
      :scheduled_start_time,
      :scheduled_end_time,
      :equipment_set_id,
      :agency_id
    ])
    |> validate_scheduled_date()
    |> validate_equipment_set_available()
    |> validate_agency_available()
    |> Ecto.Changeset.change(status: :claimed)
  end

  @doc false
  def admin_claim_changeset(pick, attrs) do
    attrs = set_end_time(attrs)

    pick
    |> cast(attrs, [
      :scheduled_date,
      :scheduled_start_time,
      :scheduled_end_time,
      :equipment_set_id,
      :agency_id
    ])
    |> validate_required([
      :scheduled_date,
      :scheduled_start_time,
      :scheduled_end_time
    ])
    |> validate_scheduled_date()
    |> validate_equipment_set_available()
    |> validate_agency_available()
    |> Ecto.Changeset.change(status: :claimed)
  end

  @doc false
  def admin_assign_lead_picker_changeset(pick, attrs) do
    attrs = set_end_time(attrs)

    pick
    |> cast(attrs, [
      :scheduled_date,
      :scheduled_start_time,
      :scheduled_end_time,
      :equipment_set_id,
      :agency_id,
      :lead_picker_id
    ])
    |> validate_required([
      :scheduled_date,
      :scheduled_start_time,
      :scheduled_end_time,
      :lead_picker_id
    ])
    |> validate_scheduled_date()
    |> validate_equipment_set_available()
    |> validate_agency_available()
    |> Ecto.Changeset.change(status: :claimed)
  end

  def admin_switch_lead_picker_changeset(pick, attrs) do
    attrs = set_end_time(attrs)

    pick
    |> cast(attrs, [
      :lead_picker_id
    ])
    |> validate_required([
      :lead_picker_id
    ])
    |> Ecto.Changeset.change(status: :claimed)
  end

  defp validate_scheduled_date(changeset) do
    scheduled_date = get_field(changeset, :scheduled_date)
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    cond do
      is_nil(scheduled_date) ->
        changeset

      Enum.member?(Date.range(start_date, end_date), scheduled_date) ->
        changeset

      true ->
        add_error(
          changeset,
          :scheduled_date,
          "The scheduled date must be between the start and end dates."
        )
    end
  end

  defp validate_pick_time(changeset) do
    has_at_least_one_pick_time =
      get_field(changeset, :pick_time_any) ||
        get_field(changeset, :pick_time_morning) ||
        get_field(changeset, :pick_time_afternoon) ||
        get_field(changeset, :pick_time_evening)

    if has_at_least_one_pick_time do
      changeset
    else
      add_error(changeset, :pick_time_any, "You must pick at least one available pick time.")
    end
  end

  defp validate_equipment_set_available(changeset) do
    equipment_set_id = get_field(changeset, :equipment_set_id)
    date = get_field(changeset, :scheduled_date)
    start_time = get_field(changeset, :scheduled_start_time)
    end_time = get_field(changeset, :scheduled_end_time)

    if is_nil(date) or is_nil(start_time) or is_nil(end_time) or is_nil(equipment_set_id) do
      changeset
    else
      pick_id = get_field(changeset, :id)

      picks_in_scheduled_time =
        Pick
        |> where([p], not (p.id == ^pick_id))
        |> where([p], p.equipment_set_id == ^equipment_set_id)
        |> where([p], p.scheduled_date == ^date)
        |> where([p], p.scheduled_start_time >= ^Time.add(start_time, -3600, :second))
        |> where([p], p.scheduled_end_time <= ^Time.add(end_time, 3600, :second))
        |> join(:left, [p], es in EquipmentSet, on: p.equipment_set_id == es.id)
        |> Repo.aggregate(:count, :id)

      if picks_in_scheduled_time > 0 do
        add_error(
          changeset,
          :equipment_set_id,
          "The equipment set is booked during this time. Please choose a different equipment set."
        )
      else
        changeset
      end
    end
  end

  defp validate_agency_available(changeset) do
    agency_id = get_field(changeset, :agency_id)
    date = get_field(changeset, :scheduled_date)
    start_time = get_field(changeset, :scheduled_start_time)
    end_time = get_field(changeset, :scheduled_end_time)

    if is_nil(date) or is_nil(start_time) or is_nil(end_time) or is_nil(agency_id) do
      changeset
    else
      agency = Repo.get!(Agency, agency_id)

      day =
        date
        |> Timex.format!("%A", :strftime)
        |> String.downcase()

      cond do
        agency.is_accepting_fruit == false ->
          add_error(
            changeset,
            :agency_id,
            "Sorry, #{agency.name} is not accepting fruit. Please pick a different agency."
          )

        Map.get(agency, String.to_existing_atom("#{day}_closed")) == true ->
          add_error(changeset, :agency_id, "Sorry, #{agency.name} is closed that day.")

        Map.get(agency, String.to_existing_atom("#{day}_hours_start")) > start_time ||
            Map.get(agency, String.to_existing_atom("#{day}_hours_end")) < end_time ->
          add_error(
            changeset,
            :agency_id,
            "Sorry, #{agency.name} is only open from #{
              SharedView.twelve_hour_time(
                Map.get(agency, String.to_existing_atom(day <> "_hours_start"))
              )
            } to #{
              SharedView.twelve_hour_time(
                Map.get(agency, String.to_existing_atom(day <> "_hours_end"))
              )
            }. Please adjust your pick time to allow travel time to the agency after the end time or choose a different agency."
          )

        true ->
          changeset
      end
    end
  end

  @doc false
  def reschedule_changeset(pick, attrs) do
    pick
    |> cast(attrs, [
      :start_date,
      :end_date,
      :pick_time_any,
      :pick_time_morning,
      :pick_time_afternoon,
      :pick_time_evening
    ])
    |> validate_required([
      :start_date,
      :end_date
    ])
    |> validate_pick_time()
    |> validate_dates()
    |> Ecto.Changeset.change(scheduled_date: nil)
    |> Ecto.Changeset.change(scheduled_start_time: nil)
    |> Ecto.Changeset.change(scheduled_end_time: nil)
    |> Ecto.Changeset.change(lead_picker_id: nil)
    |> Ecto.Changeset.change(agency_id: nil)
    |> Ecto.Changeset.change(equipment_set_id: nil)
    |> Ecto.Changeset.change(status: :rescheduled)
  end

  @doc false
  def complete_changeset(%Pick{} = pick) do
    Ecto.Changeset.change(pick, status: :completed)
  end

  @doc false
  def cancel_changeset(%Pick{} = pick, attrs) do
    pick
    |> cast(attrs, [:reason_for_cancellation])
    |> validate_required([:reason_for_cancellation])
  end

  def validate_tree_count(changeset) do
    trees = Repo.all(Ecto.assoc(changeset.data, :trees))
    valid? = length(trees) > 0

    if valid? do
      changeset
    else
      add_error(changeset, :trees, "You must pick at least one tree.")
    end
  end

  def requested_by(query \\ __MODULE__, person),
    do: from(q in query, where: q.requester_id == ^person.id)

  def public(query \\ __MODULE__), do: from(q in query, where: q.is_private == false)
  def private(query \\ __MODULE__), do: from(q in query, where: q.is_private)

  def preload_all(pick) do
    pick
    |> preload_trees()
    |> preload_snapshots()
    |> preload_requester()
    |> preload_lead_picker()
    |> preload_pickers()
    |> preload_agency()
    |> preload_agency_partner()
    |> preload_equipment_set()
    |> preload_property()
    |> preload_report()
    |> preload_report_fruit()
    |> preload_report_attendance()
  end

  def preload_list(pick) do
    pick
    |> preload_trees()
    |> preload_requester()
    |> preload_lead_picker()
    |> preload_pickers()
    |> preload_property()
  end

  def preload_trees(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :trees)
  def preload_trees(pick), do: Repo.preload(pick, :trees)

  def preload_snapshots(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :tree_snapshots)
  def preload_snapshots(pick), do: Repo.preload(pick, :tree_snapshots)

  def preload_requester(%Ecto.Query{} = query), do: Ecto.Query.preload(query, [:requester, requester: :profile])
  def preload_requester(pick), do: Repo.preload(pick, [:requester, requester: :profile])

  def preload_lead_picker(%Ecto.Query{} = query),
    do: Ecto.Query.preload(query, [:lead_picker, lead_picker: :profile])

  def preload_lead_picker(pick), do: Repo.preload(pick, [:lead_picker, lead_picker: :profile])

  def preload_pickers(%Ecto.Query{} = query),
    do: Ecto.Query.preload(query, [:pickers, pickers: :profile])

  def preload_pickers(pick), do: Repo.preload(pick, [:pickers, pickers: :profile])

  def preload_equipment_set(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :equipment_set)
  def preload_equipment_set(pick), do: Repo.preload(pick, :equipment_set)

  def preload_agency(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :agency)
  def preload_agency(pick), do: Repo.preload(pick, :agency)

  def preload_agency_partner(%Ecto.Query{} = query),
    do: Ecto.Query.preload(query, agency: :partner)

  def preload_agency_partner(pick), do: Repo.preload(pick, agency: :partner)

  def preload_property(%Ecto.Query{} = query), do: Ecto.Query.preload(query, requester: :property)
  def preload_property(pick), do: Repo.preload(pick, requester: :property)

  def preload_report(%Ecto.Query{} = query),
    do: Ecto.Query.preload(query, [:report, report: :submitter])

  def preload_report(pick), do: Repo.preload(pick, [:report, report: :submitter])

  def preload_report_fruit(%Ecto.Query{} = query),
    do: Ecto.Query.preload(query, [:report, report: :fruits])

  def preload_report_fruit(pick), do: Repo.preload(pick, [:report, report: :fruits])

  def preload_report_attendance(%Ecto.Query{} = query),
    do: Ecto.Query.preload(query, [:report, report: :attendees, report: [attendees: :person]])

  def preload_report_attendance(pick),
    do: Repo.preload(pick, [:report, report: :attendees, report: [attendees: :person]])

  defp set_end_time(attrs) do
    start_time = Map.get(attrs, "scheduled_start_time")

    if is_nil(start_time) || start_time == "" do
      attrs
    else
      # 2 hours from start time
      end_time =
        start_time
        |> Time.from_iso8601!()
        |> Time.add(7200, :second)
        |> Time.truncate(:second)
        |> Time.to_string()

      Map.put(attrs, "scheduled_end_time", end_time)
    end
  end
end
