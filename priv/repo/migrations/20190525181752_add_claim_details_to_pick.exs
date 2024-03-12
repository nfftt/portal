defmodule FruitPicker.Repo.Migrations.AddClaimDetailsToPick do
  use Ecto.Migration

  def change do
    alter table(:picks) do
      add(:scheduled_date, :date)
      add(:scheduled_start_time, :time)
      add(:scheduled_end_time, :time)
      add(:lead_picker_id, references(:people))
      add(:agency_id, references(:agencies))
      add(:equipment_set_id, references(:equipment_sets))
    end
  end
end
