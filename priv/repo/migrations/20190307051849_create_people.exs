defmodule FruitPicker.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :email, :string
      add :first_name, :string
      add :last_name, :string
      add :password_hash, :string

      timestamps()
    end

    create unique_index(:people, [:email])
  end
end
