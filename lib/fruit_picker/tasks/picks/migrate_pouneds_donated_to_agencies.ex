defmodule FruitPicker.Tasks.Picks.MigratePoundsDonatedToAgencies do
  @moduledoc """
  Insert into pick_fruit_agencies based on pick fruit total_pounds_donated

  Since we have implemented pick_fruit_agencies to pick up to 4 agencies, we need to migrate some date to the table.

  Please note that you should not run this task multiple times as it would make duplicated rows.
  """

  @shortdoc "Migration from total_pounds_donated to pick_fruit_agencies"

  import Ecto.Query, warn: false

  alias FruitPicker.Repo

  alias FruitPicker.Activities.{
    Pick,
    PickFruit,
    PickFruitAgency
  }

  def migrate_pounds_donated_to_pick_fruit_agencies do
    PickFruit
    |> join(:inner, [pf], p in Pick, on: pf.pick_id == p.id)
    |> select([pf, p], %{
      pick_fruit_id: pf.id,
      agency_id: p.agency_id,
      pounds_donated: pf.total_pounds_donated
    })
    |> Repo.all()
    |> Enum.each(&insert_pick_fruit_agencies/1)
  end

  def insert_pick_fruit_agencies(attrs) do
    %PickFruitAgency{}
    |> PickFruitAgency.changeset(attrs)
    |> Repo.insert()
  end
end
