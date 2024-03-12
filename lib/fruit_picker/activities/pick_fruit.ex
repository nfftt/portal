defmodule FruitPicker.Activities.PickFruit do
  @moduledoc """
  Data representation of picked fruit.
  """

  use FruitPicker.Schema

  alias FruitPicker.Activities.{
    Pick,
    PickReport,
    PickFruit,
    PickFruitAgency
  }

  schema "pick_fruit" do
    field(:fruit_category, :string)
    field(:fruit_quality, :string)
    field(:total_pounds_picked, :float)
    field(:total_pounds_donated, :float)

    belongs_to(:pick, Pick)
    belongs_to(:pick_report, PickReport)

    has_many(:agencies, PickFruitAgency)

    timestamps()
  end

  def changeset(pick_fruit, attrs) do
    pick_fruit
    |> cast(attrs, [
      :fruit_category,
      :fruit_quality,
      :total_pounds_picked,
      :pick_id,
      :pick_report_id
    ])
    |> cast_assoc(:agencies, with: &PickFruitAgency.changeset/2)
    |> cast_total_pounds_donated()
    |> validate_required([
      :fruit_category,
      :fruit_quality,
      :total_pounds_picked,
      :pick_id,
      :pick_report_id
    ])
    |> validate_number(:total_pounds_donated,
      greater_than: 0,
      message: "Total pounds donated to agencies must be greater than 0"
    )
  end

  defp cast_total_pounds_donated(changeset) do
    total_donated =
      get_field(changeset, :agencies)
      |> Enum.reduce(0, fn agency, acc ->
        case agency.pounds_donated do
          nil ->
            acc

          _ ->
            agency.pounds_donated + acc
        end
      end)

    put_change(changeset, :total_pounds_donated, total_donated)
  end

  def preload_all(pick_fruit) do
    pick_fruit
    |> preload_pick()
    |> preload_pick_report()
  end

  def preload_pick(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :pick)
  def preload_pick(pick), do: Repo.preload(pick, :pick)

  def preload_pick_report(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :pick_report)
  def preload_pick_report(pick_fruit), do: Repo.preload(pick_fruit, :pick_report)
  def preload_agencies(pick_fruit), do: Repo.preload(pick_fruit, :agencies)
end
