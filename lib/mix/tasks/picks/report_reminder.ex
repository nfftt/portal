defmodule Mix.Tasks.Picks.ReportReminder do
  @moduledoc """
  Send out an email to remind lead pickers to submit outstanding reports.
  """

  @shortdoc "Send lead pickers an email re: oustanding reports"

  use Mix.Task

  import FruitPicker.Tasks.Picks.ReportReminder, only: [send_out_email: 0]

  def run(_args) do
    Mix.Task.run("app.start")
    send_out_email()
  end
end
