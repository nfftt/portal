defmodule FruitPicker.Repo.Migrations.AddDeactivateReasonToTree do
  use Ecto.Migration

  def change do
    alter table(:trees) do
      add(:deactivate_reason, :string)
    end
  end
end
