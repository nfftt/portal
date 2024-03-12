defmodule FruitPicker.Repo.Migrations.ChangeTreeSprayed do
  use Ecto.Migration

  def up do
    alter table(:trees) do
      remove(:is_tree_sprayed_or_treated)
      add(:is_tree_sprayed_or_treated, :string, default: "No")
    end
  end

  def down do
    alter table(:trees) do
      remove(:is_tree_sprayed_or_treated)
      add(:is_tree_sprayed_or_treated, :boolean, default: false)
    end
  end
end
