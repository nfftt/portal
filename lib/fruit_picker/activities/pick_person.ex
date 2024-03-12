defmodule FruitPicker.Activities.PickPerson do
  @moduledoc """
  Data representation of which people are associated with a pick.
  """

  use FruitPicker.Schema

  alias FruitPicker.Activities.Pick
  alias FruitPicker.Accounts.Person

  schema "picks_people" do
    belongs_to(:pick, Pick)
    belongs_to(:person, Person)
    timestamps()
  end

  @doc false
  def changeset(pick_person, attrs \\ %{}) do
    pick_person
    |> cast(attrs, [:pick_id, :person_id])
    |> validate_required([:pick_id, :person_id])
  end

  def preload_all(pick_person) do
    pick_person
    |> preload_pick()
    |> preload_person()
  end

  def preload_pick(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :pick)
  def preload_pick(pick_person), do: Repo.preload(pick_person, :pick)

  def preload_person(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :person)
  def preload_person(pick_person), do: Repo.preload(pick_person, :person)
end
