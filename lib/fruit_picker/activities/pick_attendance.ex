defmodule FruitPicker.Activities.PickAttendance do
  @moduledoc """
  Data representation of who attended a pick.
  """

  use FruitPicker.Schema

  alias FruitPicker.Activities.PickReport
  alias FruitPicker.Accounts.Person

  schema "pick_attendance" do
    field(:did_attend, :boolean, default: false)

    belongs_to(:pick_report, PickReport)
    belongs_to(:person, Person)

    timestamps()
  end

  def changeset(attendance, attrs \\ %{}) do
    attendance
    |> cast(attrs, [:pick_report_id, :person_id])
    |> validate_required([:pick_report_id, :person_id])
  end

  def preload_all(attendance) do
    attendance
    |> preload_pick_report()
    |> preload_person()
  end

  def preload_pick_report(%Ecto.Query{} = query), do: Ecto.Query.preload(query, [:pick_report, pick_report: :pick])
  def preload_pick_report(attendance), do: Repo.preload(attendance, [:pick_report, pick_report: :pick])

  def preload_person(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :person)
  def preload_person(attendance), do: Repo.preload(attendance, :person)
end
