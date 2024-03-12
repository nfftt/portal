defmodule FruitPicker.Repo.Migrations.AddPicks do
  use Ecto.Migration
  alias FruitPicker.Activities.Pick.StatusEnum

  def up do
    StatusEnum.create_type()

    create table(:picks) do
      add(:tree_owner_takes, :string)
      add(:start_date, :date)
      add(:end_date, :date)
      add(:ladder_provided, :boolean, default: false)
      add(:notes, :text)

      add(:pick_time_any, :boolean, default: false)
      add(:pick_time_morning, :boolean, default: false)
      add(:pick_time_afternoon, :boolean, default: false)
      add(:pick_time_evening, :boolean, default: false)

      add(:status, StatusEnum.type(), default: "started")

      add(:requester_id, references(:people), null: false)
      timestamps()
    end

    create table(:picks_trees) do
      add(:pick_id, references(:picks), null: false)
      add(:tree_id, references(:trees), null: false)
      timestamps()
    end
  end

  def down do
    drop table(:picks)
    drop table(:picks_trees)
    StatusEnum.drop_type()
  end
end
