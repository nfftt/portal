defmodule Mix.Tasks.Accounts.UpdateMembershipEndDate do
  @moduledoc """
  Task to update membership payments that are missing an end date.
  """

  @shortdoc "Update end_date of membership payment"

  use Mix.Task

  import FruitPicker.Tasks.Accounts.UpdateMembershipEndDate, only: [update_membership_payments: 0]

  def run(_args) do
    Mix.Task.run("app.start")
    update_membership_payments()
  end
end
