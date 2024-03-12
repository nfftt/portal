defmodule FruitPicker.Tasks.Accounts.MarkPersonInactive do
  @moduledoc """
  Task to update the person model to inactive is there is not a recent payment.
  """

  @shortdoc "Update membership_is_active of person"

  import Ecto.Query, warn: false
  require Logger

  alias FruitPicker.Repo
  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.{Person, MembershipPayment}

  def update_membership_status do
    cutoff_date = Accounts.get_next_season_cutoff_date!()

    Logger.info("cutoff_date: #{cutoff_date}")

    MembershipPayment
    |> join(:right, [mp], person in Person, on: mp.member_id == person.id)
    |> where(
      [mp, person],
      person.role == "user" and person.membership_is_active == true and
        not (mp.end_date >= ^cutoff_date)
    )
    |> or_where(
      [mp, person],
      person.role == "user" and person.membership_is_active == true and is_nil(mp)
    )
    |> where([mp, person], not is_nil(person))
    |> order_by([mp, person], person.id)
    |> select([mp, person], person)
    |> distinct(true)
    |> Repo.all()
    |> Enum.each(fn person ->
      changeset = Person.inactive_membership_changeset(person)

      Repo.update!(changeset)

      Logger.info(
        "Updated #{person.first_name} #{person.last_name} (#{person.id}) to an inactive membership"
      )
    end)
  end
end
