defmodule Mix.Tasks.Picks.Complete do
  @moduledoc """
  Update the status of picks to completed.

  Queries all of the picks to find "claimed" picks which have a scheduled
  date older than today. Also finds picks that have a scheduled date of
  today, but then confirms that the scheduled end time as already passed.
  """

  @shortdoc "Marks appropriate picks as completed"

  use Mix.Task

  import FruitPicker.Tasks.Picks.Complete, only: [complete_picks: 0]

  def run(_args) do
    Mix.Task.run("app.start")
    complete_picks()
  end
end
