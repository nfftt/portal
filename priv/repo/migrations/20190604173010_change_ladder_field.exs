defmodule FruitPicker.Repo.Migrations.ChangeLadderField do
  use Ecto.Migration

  def up do
    alter table(:properties) do
      remove(:ladder_provided)
      add(:ladder_provided, :string, default: "Yes, I'll provide a ladder")
    end

    alter table(:picks) do
      remove(:ladder_provided)
      add(:ladder_provided, :string, default: "Yes, I'll provide a ladder")
    end
  end

  def down do
    alter table(:properties) do
      remove(:ladder_provided)
      add(:ladder_provided, :boolean, default: true)
    end

    alter table(:picks) do
      remove(:ladder_provided)
      add(:ladder_provided, :boolean, default: true)
    end
  end
end
