defmodule FruitPicker.Activities.PickFruitAgency do
  use FruitPicker.Schema

  alias FruitPicker.Activities.PickFruit
  alias FruitPicker.Partners.Agency

  schema "pick_fruit_agencies" do
    field :pounds_donated, :float

    belongs_to(:pick_fruit, PickFruit)
    belongs_to(:agency, Agency)

    timestamps()
  end

  def changeset(pick_fruit_agency, attrs) do
    pick_fruit_agency
    |> cast(attrs, [:agency_id, :pick_fruit_id, :pounds_donated])
    |> validate_required([:agency_id, :pounds_donated])
    |> case do
      %{valid?: false, changes: changes} = changeset when changes == %{} ->
        # If the changeset is invalid and has no changes, it is
        # because all required fields are missing, so we ignore it.
        %{changeset | action: :ignore}

      changeset ->
        changeset
    end
  end
end
