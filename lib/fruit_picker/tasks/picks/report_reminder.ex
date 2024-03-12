defmodule FruitPicker.Tasks.Picks.ReportReminder do
  @moduledoc """
  Send out an email to remind lead pickers to submit outstanding reports.
  """

  @shortdoc "Send lead pickers an email re: oustanding reports"

  import Ecto.Query, warn: false
  import Logger

  alias FruitPicker.Mailer
  alias FruitPicker.Activities
  alias FruitPickerWeb.Email

  def send_out_email do
    Logger.info("Starting `Tasks.Picks.ReportReminder.send_out_email/0`")

    picks = find_all_picks_with_outstanding_report()

    Enum.each(picks, fn pick ->
      if is_nil(pick.lead_picker) do
        Logger.info("Cannot send report reminder for pick ##{pick.id} since it is unclaimed")
      else
        pick
        |> Email.outstanding_report_reminder_email(pick.lead_picker)
        |> Mailer.deliver_later()
      end
    end)
  end

  defp find_all_picks_with_outstanding_report do
    Activities.picks_with_late_outstanding_report()
  end
end
