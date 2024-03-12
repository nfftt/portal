defmodule FruitPicker.Repo.Migrations.AddDidAttendToAttendance do
  use Ecto.Migration

  def change do
    alter table(:pick_attendance) do
      add(:did_attend, :boolean, default: :true)
    end
  end
end
