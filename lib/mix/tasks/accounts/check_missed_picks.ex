defmodule Mix.Tasks.Accounts.CheckMissedPicks do
  @moduledoc """
  Task to deactivate accounts for the season if they hit 3 missed picks.
  """

  @shortdoc "Deactivate accounts for the season"

  use Mix.Task

  import FruitPicker.Tasks.Accounts.CheckMissedPicks, only: [deactivate_accounts: 0]

  def run(_args) do
    Mix.Task.run("app.start")
    deactivate_accounts()
  end
end
