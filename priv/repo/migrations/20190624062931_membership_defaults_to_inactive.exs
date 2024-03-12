defmodule FruitPicker.Repo.Migrations.MembershipDefaultsToInactive do
  use Ecto.Migration

  def up do
    alter table(:people) do
      modify(:membership_is_active, :boolean, default: false)
    end
  end

  def down do
    alter table(:people) do
      modify(:membership_is_active, :boolean, default: true)
    end
  end
end
