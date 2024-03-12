defmodule FruitPicker.Activities.PickReport do
  @moduledoc """
  Data representation of pick reports for recording how
  much fruit was donated and kept.
  """

  use FruitPicker.Schema

  alias FruitPicker.Activities.{
    Pick,
    PickAttendance,
    PickFruit
  }

  alias FruitPicker.Accounts.{Person, TreeSnapshot}

  schema "pick_reports" do
    field(:has_equipment_set_issue, :boolean, default: false)
    field(:equipment_set_issue_details, :string)
    field(:has_fruit_delivered_to_agency, :boolean, default: true)
    field(:fruit_delivered_to_agency_details, :string)
    field(:has_issues_on_site, :boolean, default: false)
    field(:issues_on_site_details, :string)
    field(:other_details, :string)

    field(:is_complete, :boolean, default: false)

    belongs_to(:pick, Pick)
    belongs_to(:submitter, Person)
    has_many(:fruits, PickFruit)
    has_many(:attendees, PickAttendance)

    timestamps()
  end

  def changeset(pick_report, attrs) do
    pick_report
    |> cast(attrs, [
      :has_equipment_set_issue,
      :equipment_set_issue_details,
      :has_fruit_delivered_to_agency,
      :fruit_delivered_to_agency_details,
      :has_issues_on_site,
      :issues_on_site_details,
      :other_details,
      :pick_id,
      :submitter_id
    ])
    |> cast_assoc(:fruits)
    |> validate_equipment_set()
    |> validate_delivered()
    |> validate_site()
    |> validate_required([
      :has_equipment_set_issue,
      :has_fruit_delivered_to_agency,
      :has_issues_on_site,
      :pick_id,
      :submitter_id
    ])
  end

  defp validate_equipment_set(changeset) do
    has_issue = get_field(changeset, :has_equipment_set_issue)
    details = get_field(changeset, :equipment_set_issue_details)

    add_error(changeset, :equipment_set_issue_details, "Please provide details of the issue.")

    if has_issue and is_nil(details) do
      add_error(changeset, :equipment_set_issue_details, "Please provide details of the issue.")
    else
      changeset
    end
  end

  defp validate_delivered(changeset) do
    delivered = get_field(changeset, :has_fruit_delivered_to_agency)
    details = get_field(changeset, :fruit_delivered_to_agency_details)

    if not delivered and is_nil(details) do
      add_error(
        changeset,
        :fruit_delivered_to_agency_details,
        "Please provide details as to why the fruit could not be delivered."
      )
    else
      changeset
    end
  end

  defp validate_site(changeset) do
    has_issue = get_field(changeset, :has_issues_on_site)
    details = get_field(changeset, :issues_on_site_details)

    if has_issue and is_nil(details) do
      add_error(changeset, :issues_on_site_details, "Please provide details of the issue.")
    else
      changeset
    end
  end

  def preload_all(report) do
    report
    |> preload_pick()
    |> preload_fruits()
    |> preload_attendees()
    |> preload_agencies()
  end

  def preload_pick(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :pick)
  def preload_pick(report), do: Repo.preload(report, :pick)

  def preload_fruits(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :fruits)
  def preload_fruits(report), do: Repo.preload(report, :fruits)

  def preload_attendees(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :attendees)
  def preload_attendees(report), do: Repo.preload(report, :attendees)

  def preload_agencies(%Ecto.Query{} = query), do: Ecto.Query.preload(query, fruits: :agencies)
  def preload_agencies(report), do: Repo.preload(report, fruits: :agencies)
end
