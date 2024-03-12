defmodule FruitPicker.Repo.Migrations.AddAvatarToPerson do
  use Ecto.Migration

  def change do
    alter table(:people) do
      add(:avatar, :string)
    end
  end
end
