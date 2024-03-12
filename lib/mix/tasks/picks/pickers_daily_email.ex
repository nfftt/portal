defmodule Mix.Tasks.Picks.PickersDailyEmail do
  @moduledoc """
  Send out an email with available pick info to active fruit pickers.
  """

  @shortdoc "Send pickers available picks email"

  use Mix.Task

  import FruitPicker.Tasks.Picks.PickersDailyEmail, only: [send_out_email: 0]

  def run(_args) do
    Mix.Task.run("app.start")
    send_out_email()
  end
end
