defmodule Mix.Tasks.Picks.Reminders do
  @moduledoc """
  Sends out pick reminders.

  Find picks that occurring tomorrow and send out reminders to
  the agency, tree owner, and pickers.
  """

  @shortdoc "Send out pick reminder emails"

  use Mix.Task

  import FruitPicker.Tasks.Picks.Reminders, only: [pick_reminders: 0]

  def run(_args) do
    Mix.Task.run("app.start")
    pick_reminders()
  end
end
