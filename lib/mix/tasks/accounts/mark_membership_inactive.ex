defmodule Mix.Tasks.Accounts.MarkPersonInactive do
  @moduledoc """
  Task to update the person model to inactive is there is not a recent payment.
  """

  @shortdoc "Update membership_is_active of person"

  use Mix.Task

  import FruitPicker.Tasks.Accounts.MarkPersonInactive, only: [update_membership_status: 0]

  def run(_args) do
    Mix.Task.run("app.start")
    update_membership_status()
  end
end
