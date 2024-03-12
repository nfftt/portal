defmodule FruitPicker.Repo.Migrations.AddMembershipPayments do
  use Ecto.Migration

  def change do
    create table(:membership_payments) do
      add(:email, :string)
      add(:type, :string)
      add(:amount_in_cents, :integer)
      add(:start_date, :date)
      add(:end_date, :date)
      add(:member_id, references(:people))

      timestamps()
    end

    alter table(:people) do
      add(:membership_is_active, :boolean, default: true)
    end
  end
end
