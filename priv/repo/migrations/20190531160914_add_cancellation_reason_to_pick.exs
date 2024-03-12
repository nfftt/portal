defmodule FruitPicker.Repo.Migrations.AddCancellationReasonToPick do
  use Ecto.Migration

  def change do
    alter table(:picks) do
      add(:reason_for_cancellation, :string)
    end
  end
end
