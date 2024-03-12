defmodule FruitPicker.Repo.Migrations.AddPrivateAndNumberVolunteersToPicks do
  use Ecto.Migration

  def change do
    alter table(:picks) do
      add(:volunteers_min, :integer)
      add(:volunteers_max, :integer)
      add(:is_private, :boolean, default: false)
    end
  end
end
