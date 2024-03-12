defmodule FruitPicker.Tasks.Accounts.UpdateMembershipEndDate do
  @moduledoc """
  Task to update membership payments that are missing an end date.
  """

  @shortdoc "Update end_date of membership payment"
  require Logger
  import Ecto.Query, warn: false

  alias FruitPicker.Repo
  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.{Person, MembershipPayment}

  def update_membership_payments do
    MembershipPayment
    |> where([mp], is_nil(mp.end_date))
    |> Repo.all()
    |> Enum.each(fn payment ->
      end_date = Accounts.get_next_season_cutoff_date!(payment.start_date.year)

      payment_changeset =
        MembershipPayment.changeset(
          payment,
          Map.put(%{}, "end_date", end_date)
        )

      Repo.update!(payment_changeset)
      Logger.info("Updated payment with id #{payment.id} with new end date: #{end_date}.")
    end)
  end
end
