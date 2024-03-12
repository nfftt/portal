defmodule FruitPicker.Tasks.Picks.Reminders do
  @moduledoc """
  Sends out pick reminders.

  Find picks that occurring tomorrow and send out reminders to
  the agency, tree owner, and pickers.
  """

  @shortdoc "Send out pick reminder emails"

  require Logger
  import Ecto.Query, warn: false

  alias FruitPicker.{Mailer, Repo}
  alias FruitPicker.Activities
  alias FruitPicker.Activities.Pick
  alias FruitPickerWeb.Email

  def pick_reminders do
    picks = get_tomorrow_picks()
    Logger.info("Starting `Tasks.Picks.Reminders.pick_reminders/0`")

    Logger.info("Sending reminders for #{length(picks)} picks")

    picks
    |> Enum.each(fn pick ->
      tree_owner_reminder(pick)
      agency_reminder(pick)
      pickers_reminder(pick)
    end)
  end

  defp get_tomorrow_picks() do
    tomorrow = Timex.now() |> Timex.shift(days: 1) |> Timex.to_date()

    Pick
    |> where([p], p.status == ^"claimed")
    |> where([p], p.scheduled_date == ^tomorrow)
    |> Pick.preload_agency()
    |> Pick.preload_requester()
    |> Pick.preload_lead_picker()
    |> Pick.preload_pickers()
    |> Pick.preload_trees()
    |> Pick.preload_property()
    |> Repo.all()
  end

  defp tree_owner_reminder(%Pick{} = pick) do
    Email.tree_owner_pick_reminder(pick.requester, pick)
    |> Mailer.deliver_later()
  end

  defp agency_reminder(%Pick{} = pick) do
    Email.agency_pick_reminder(pick.agency, pick)
    |> Mailer.deliver_later()
  end

  defp pickers_reminder(%Pick{} = pick) do
    pick.pickers
    |> Enum.each(fn picker ->
      Email.picker_pick_reminder(picker, pick)
      |> Mailer.deliver_later()
    end)
  end
end
