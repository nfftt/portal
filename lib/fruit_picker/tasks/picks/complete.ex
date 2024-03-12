defmodule FruitPicker.Tasks.Picks.Complete do
  @moduledoc """
  Update the status of picks to completed.

  Queries all of the picks to find "claimed" picks which have a scheduled
  date older than today. Also finds picks that have a scheduled date of
  today, but then confirms that the scheduled end time as already passed.
  """

  @shortdoc "Marks appropriate picks as completed"

  import Ecto.Query, warn: false

  alias FruitPicker.Repo
  alias FruitPicker.Activities.Pick

  require Logger

  def complete_picks do
    Logger.info("Starting `Tasks.Picks.Complete.complete_picks/0`")

    picks = find_all_claimed_picks_past_end_time()

    if picks == [] do
      Logger.info("No picks require updating their status to completed.")
    end

    Enum.each(picks, fn pk ->
      update_pick_status_to_complete(pk)
      Logger.info("Updated pick with id #{pk.id} to completed.")
    end)
  end

  defp update_pick_status_to_complete(%Pick{} = pick) do
    Repo.update!(Pick.complete_changeset(pick))
  end

  defp find_all_claimed_picks_past_end_time do
    today = Timex.now("America/Toronto") |> Timex.to_date()
    now = Time.utc_now() |> Time.add(-14_400, :second)

    Pick
    |> where([p], p.status == "claimed" and p.scheduled_date < ^today)
    |> or_where(
      [p],
      p.status == "claimed" and p.scheduled_date == ^today and p.scheduled_end_time < ^now
    )
    |> Repo.all()
  end
end
