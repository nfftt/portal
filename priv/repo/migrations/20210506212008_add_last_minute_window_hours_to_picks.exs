defmodule FruitPicker.Repo.Migrations.AddLastMinuteWindowHoursToPicks do
  use Ecto.Migration

  def change do
    alter table(:picks) do
      add(:last_minute_window_hours, :integer, default: 5, null: false)
    end
  end
end
