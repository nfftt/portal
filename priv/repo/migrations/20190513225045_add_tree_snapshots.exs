defmodule FruitPicker.Repo.Migrations.AddTreeSnapshots do
  use Ecto.Migration

  def change do
    create table(:tree_snapshots) do
      add(:receive_mulching, :boolean)
      add(:receive_watering, :boolean)
      add(:receive_pruning, :boolean)
      add(:receive_other, :string)

      # Structural
      add(:has_broken_branches, :boolean)
      add(:has_limbs_missing_bark, :boolean)
      add(:has_bare_branches_no_growth, :boolean)
      add(:has_rotten_wood, :boolean)
      add(:has_large_trunk_cracks, :boolean)
      add(:has_mushrooms_at_base, :boolean)
      add(:has_trunk_strong_lean, :boolean)
      add(:has_no_issues, :boolean)

      # Pest Evidence
      add(:pests_on_tree, :boolean)
      add(:pests_yellow_spots_on_leaves, :boolean)
      add(:pests_swollen_twisted_branches, :boolean)
      add(:pests_leaves_small_dark_spots_holes, :boolean)
      add(:pests_brown_spots_fruit_scabs, :boolean)
      add(:pests_rotting_fruit_on_branches, :boolean)
      add(:pests_powdery_mildew, :boolean)
      add(:pests_dried_out_leaves_withering_fruit, :boolean)
      add(:pests_oozing_sappy_liquid, :boolean)
      add(:pests_none, :boolean)

      add(:tree_id, references(:trees), null: false)

      timestamps()
    end
  end
end
