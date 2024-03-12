defmodule FruitPicker.Repo.Migrations.AddPickReportsAttendanceFruit do
  use Ecto.Migration

  def up do
    create table(:pick_reports) do
      add(:has_equipment_set_issue, :boolean, default: false)
      add(:equipment_set_issue_details, :text)
      add(:has_fruit_delivered_to_agency, :boolean, default: false)
      add(:fruit_delivered_to_agency_details, :text)
      add(:has_issues_on_site, :boolean, default: false)
      add(:issues_on_site_details, :text)

      add(:is_complete, :boolean, default: :false)

      add(:pick_id, references(:picks), null: false)
      add(:submitter_id, references(:people), null: false)

      timestamps()
    end

    create table(:pick_attendance) do
      add(:pick_report_id, references(:pick_reports))
      add(:person_id, references(:people))

      timestamps()
    end

    create table(:pick_fruit) do
      add(:fruit_category, :string)
      add(:fruit_quality, :string)
      add(:total_pounds_picked, :float)
      add(:total_pounds_donated, :float)

      add(:pick_id, references(:picks))
      add(:pick_report_id, references(:pick_reports))

      timestamps()
    end

    alter table(:picks) do
      add(:report_id, references(:pick_reports))
    end

    create index(:pick_reports, [:pick_id])
    create index(:pick_attendance, [:pick_report_id, :person_id])
    create index(:pick_fruit, [:pick_report_id, :pick_id])
  end

  def down do
    drop table(:pick_reports)
    drop table(:pick_fruit)
    drop table(:pick_attendance)

    alter table(:picks) do
      remove(:report_id)
    end

    drop index(:pick_reports, [:pick_id])
    drop index(:pick_attendance, [:pick_report_id, :person_id])
    drop index(:pick_fruit, [:pick_report_id, :pick_id])
  end
end
