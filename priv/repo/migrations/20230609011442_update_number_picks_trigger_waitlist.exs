defmodule FruitPicker.Repo.Migrations.UpdateNumberPicksTriggerWaitlist do
  use Ecto.Migration

  def up do
    alter table :people do
      modify :number_picks_trigger_waitlist, :integer, default: 5
    end

    FruitPicker.Repo.update_all("people", set: [number_picks_trigger_waitlist: 5])
  end

  def down do
    alter table :people do
      modify :number_picks_trigger_waitlist, :integer, default: 3
    end

    FruitPicker.Repo.update_all("people", set: [number_picks_trigger_waitlist: 3])
  end
end
