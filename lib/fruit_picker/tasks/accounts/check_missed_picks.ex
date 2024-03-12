defmodule FruitPicker.Tasks.Accounts.CheckMissedPicks do
  @moduledoc """
  Task to deactivate accounts for the season if they hit 3 missed picks.
  """

  @shortdoc "Deactivate accounts for the season"

  import Ecto.Query, warn: false

  alias FruitPicker.Repo
  alias FruitPicker.Accounts.Person

  alias FruitPicker.Activities.{
    PickAttendance,
    Pick,
    PickReport
  }

  alias FruitPickerWeb.Email
  alias FruitPicker.Mailer

  def deactivate_accounts do
    year = Date.utc_today().year

    beginning = NaiveDateTime.from_erl!({{year, 1, 1}, {0, 0, 0}})
    ending = NaiveDateTime.from_erl!({{year, 12, 31}, {0, 0, 0}})

    missed_pick_count =
      from pa in PickAttendance,
        where: pa.did_attend == false,
        join: pr in PickReport,
        on: pa.pick_report_id == pr.id,
        join: p in Pick,
        on: pr.pick_id == p.id,
        where: p.scheduled_date >= ^beginning and p.scheduled_date <= ^ending,
        group_by: [pa.person_id],
        select: %{should_deactivated: count(pa.person_id) > 2, person_id: pa.person_id}

    query =
      from pa in subquery(missed_pick_count),
        where: pa.should_deactivated == true,
        join: p in Person,
        on: pa.person_id == p.id,
        select: p

    people = Repo.all(query)

    if Enum.count(people) > 0 do
      Repo.all(Person.admins())
      |> Enum.each(fn a ->
        a
        |> Email.deactivated_accounts_notifier(people)
        |> Mailer.deliver_later()
      end)
    end
  end
end
