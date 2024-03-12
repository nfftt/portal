defmodule FruitPicker.Repo.Migrations.AddPasswordResetTokens do
  use Ecto.Migration

  def change do
    create table(:password_reset_tokens) do
      add :value, :string
      add :person_id, references(:people, on_delete: :delete_all)

      timestamps(updated_at: false)
    end

    create index(:password_reset_tokens, [:person_id])
    create unique_index(:password_reset_tokens, [:value])
  end
end
