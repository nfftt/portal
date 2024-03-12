defmodule FruitPicker.Accounts.TreeSnapshot do
  @moduledoc """
  Data representation of tree health updates.
  """

  use FruitPicker.Schema

  alias FruitPicker.Accounts.{
    Property,
    Tree,
    TreeSnapshot
  }
  alias FruitPicker.Activities.Pick

  schema "tree_snapshots" do
    field(:receive_mulching, :boolean)
    field(:receive_watering, :boolean)
    field(:receive_pruning, :boolean)
    field(:receive_other, :string)

    # Structural
    field(:has_broken_branches, :boolean)
    field(:has_limbs_missing_bark, :boolean)
    field(:has_bare_branches_no_growth, :boolean)
    field(:has_rotten_wood, :boolean)
    field(:has_large_trunk_cracks, :boolean)
    field(:has_mushrooms_at_base, :boolean)
    field(:has_trunk_strong_lean, :boolean)
    field(:has_no_issues, :boolean)

    # Pest Evidence
    field(:pests_on_tree, :boolean)
    field(:pests_yellow_spots_on_leaves, :boolean)
    field(:pests_swollen_twisted_branches, :boolean)
    field(:pests_leaves_small_dark_spots_holes, :boolean)
    field(:pests_brown_spots_fruit_scabs, :boolean)
    field(:pests_rotting_fruit_on_branches, :boolean)
    field(:pests_powdery_mildew, :boolean)
    field(:pests_dried_out_leaves_withering_fruit, :boolean)
    field(:pests_oozing_sappy_liquid, :boolean)
    field(:pests_none, :boolean)

    belongs_to(:tree, Tree)
    belongs_to(:pick, Pick)

    timestamps()
  end

  @doc false
  def changeset(tree_snapshot, attrs) do
    tree_snapshot
    |> cast(attrs, [
          :receive_mulching,
          :receive_watering,
          :receive_pruning,
          :receive_other,
          :has_broken_branches,
          :has_limbs_missing_bark,
          :has_bare_branches_no_growth,
          :has_rotten_wood,
          :has_large_trunk_cracks,
          :has_mushrooms_at_base,
          :has_trunk_strong_lean,
          :has_no_issues,
          :pests_on_tree,
          :pests_yellow_spots_on_leaves,
          :pests_swollen_twisted_branches,
          :pests_leaves_small_dark_spots_holes,
          :pests_brown_spots_fruit_scabs,
          :pests_rotting_fruit_on_branches,
          :pests_powdery_mildew,
          :pests_dried_out_leaves_withering_fruit,
          :pests_oozing_sappy_liquid,
          :pests_none,
        ])
    |> validate_required([
          :receive_mulching,
          :receive_watering,
          :receive_pruning,
          :has_broken_branches,
          :has_limbs_missing_bark,
          :has_bare_branches_no_growth,
          :has_rotten_wood,
          :has_large_trunk_cracks,
          :has_mushrooms_at_base,
          :has_trunk_strong_lean,
          :has_no_issues,
          :pests_on_tree,
          :pests_yellow_spots_on_leaves,
          :pests_swollen_twisted_branches,
          :pests_leaves_small_dark_spots_holes,
          :pests_brown_spots_fruit_scabs,
          :pests_rotting_fruit_on_branches,
          :pests_powdery_mildew,
          :pests_dried_out_leaves_withering_fruit,
          :pests_oozing_sappy_liquid,
          :pests_none,
        ])
    |> foreign_key_constraint(:tree_id)
  end

  def preload_all(tree_snapshot) do
    tree_snapshot
    |> preload_tree()
    |> preload_pick()
  end

  def preload_tree(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :tree)
  def preload_tree(tree_snapshot), do: Repo.preload(tree_snapshot, :tree)

  def preload_pick(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :pick)
  def preload_pick(tree_snapshot), do: Repo.preload(tree_snapshot, :pick)
end
