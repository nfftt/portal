defmodule FruitPicker.Repo.Migrations.AddOtherDetailsPickReport do
  use Ecto.Migration

  def change do
    alter table("pick_reports") do
      add :other_details, :text
    end
  end
end
