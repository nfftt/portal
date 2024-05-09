defmodule FruitPicker.Accounts.MembershipPayment do
  @moduledoc """
  Data representation of membership dues paid via Stripe
  and received through the webhook.
  """

  use FruitPicker.Schema

  alias FruitPicker.Accounts.Person

  schema "membership_payments" do
    field(:stripe_payment_intent_id, :string)
    field(:email, :string)
    field(:type, :string)
    field(:amount_in_cents, :integer)
    field(:start_date, :date)
    field(:end_date, :date)

    belongs_to(:member, Person)

    timestamps()
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [
          :stripe_payment_intent_id,
          :email,
          :type,
          :amount_in_cents,
          :member_id,
          :start_date,
          :end_date
        ])
    |> validate_required([
          :email,
          :type,
          :amount_in_cents,
          :member_id,
          :start_date,
          :end_date
      ])
    |> assoc_constraint(:member)
  end
end
