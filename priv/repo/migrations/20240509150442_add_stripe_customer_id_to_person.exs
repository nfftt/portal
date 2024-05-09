defmodule FruitPicker.Repo.Migrations.AddStripeCustomerIdToPerson do
  use Ecto.Migration

  def change do
    alter table(:people) do
      add :stripe_customer_id, :string
    end

    alter table(:membership_payments) do
      add :stripe_payment_intent_id, :string
    end
  end
end
