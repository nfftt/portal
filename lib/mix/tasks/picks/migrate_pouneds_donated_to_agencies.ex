defmodule Mix.Tasks.Picks.MigratePoundsDonatedToAgencies do
  @moduledoc """
  Insert into pick_fruit_agencies based on pick fruit total_pounds_donated

  Since we have implemented pick_fruit_agencies to pick up to 4 agencies, we need to migrate some date to the table.

  Please note that you should not run this task multiple times as it would make duplicated rows.
  """

  @shortdoc "Migration from total_pounds_donated to pick_fruit_agencies"

  use Mix.Task

  import FruitPicker.Tasks.Picks.MigratePoundsDonatedToAgencies,
    only: [migrate_pounds_donated_to_pick_fruit_agencies: 0]

  def run(_args) do
    Mix.Task.run("app.start")
    migrate_pounds_donated_to_pick_fruit_agencies()
  end
end
