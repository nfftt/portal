defmodule FruitPicker.Repo.Migrations.AddNumberPicksTriggerWaitlist do
  use Ecto.Migration

  def change do
    alter table("people") do
      add :number_picks_trigger_waitlist, :integer, default: 3
    end
  end
end
