defmodule FruitPicker.Repo.Migrations.FixProfileIndex do
  use Ecto.Migration

  def up do
    drop(constraint(:people, "people_profile_id_fkey"))

    alter table(:people) do
      modify(:profile_id, references(:profiles, on_delete: :delete_all))
    end
  end

  def down do
    drop(constraint(:people, "people_profile_id_fkey"))

    alter table(:people) do
      modify(:profile_id, references(:profiles, on_delete: :nothing), null: true)
    end
  end
end
