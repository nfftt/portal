defmodule FruitPicker.Accounts.Tree do
  @moduledoc """
  Data representation of a property owner's trees.
  """

  use FruitPicker.Schema

  alias FruitPicker.Accounts.{
    Property,
    Tree,
    TreeSnapshot
  }
  alias FruitPicker.Activities.{Pick, PickTree}

  schema "trees" do
    field(:nickname, :string)
    field(:is_active, :boolean)
    field(:pickable_this_year, :boolean)
    field(:unpickable_reason, :string)
    field(:type, :string)
    field(:fruit_variety, :string)
    field(:height, :string)
    field(:earliest_ripening_date, :date)
    field(:year_planted, :string)
    field(:tree_pruned_frequency, :string)
    field(:is_tree_sprayed_or_treated, :string)

    field(:deactivate_reason, :string)

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

    belongs_to(:property, Property)
    has_many(:snapshots, TreeSnapshot)
    many_to_many(:picks, Pick, join_through: PickTree)

    timestamps()
  end

  @doc false
  def changeset(tree, attrs) do
    tree
    |> cast(attrs, [
          :nickname,
          :is_active,
          :pickable_this_year,
          :unpickable_reason,
          :type,
          :fruit_variety,
          :height,
          :earliest_ripening_date,
          :year_planted,
          :tree_pruned_frequency,
          :is_tree_sprayed_or_treated,
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
          :pickable_this_year,
          :type,
          :height,
          :earliest_ripening_date,
          :year_planted,
          :tree_pruned_frequency,
          :is_tree_sprayed_or_treated,
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
    |> assoc_constraint(:property)
  end

  @doc false
  def edit_changeset(tree, attrs) do
    tree
    |> cast(attrs, [
          :nickname,
          :is_active,
          :pickable_this_year,
          :unpickable_reason,
          :type,
          :fruit_variety,
          :height,
          :earliest_ripening_date,
          :year_planted,
          :tree_pruned_frequency,
          :is_tree_sprayed_or_treated,
        ])
    |> validate_required([
          :pickable_this_year,
          :type,
          :height,
          :earliest_ripening_date,
          :year_planted,
          :tree_pruned_frequency,
          :is_tree_sprayed_or_treated,
      ])
  end

  @doc false
  def deactivate_changeset(tree, attrs) do
    tree
    |> cast(attrs, [:deactivate_reason])
    |> validate_required([:deactivate_reason])
    |> put_change(:is_active, false)
  end

  def preload_all(tree) do
    tree
    |> preload_property()
    |> preload_snapshots()
    |> preload_picks()
  end

  def preload_property(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :property)
  def preload_property(tree), do: Repo.preload(tree, :property)

  def preload_snapshots(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :snapshots)
  def preload_snapshots(tree), do: Repo.preload(tree, :snapshots)

  def preload_picks(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :picks)
  def preload_ppropertyroperty(tree), do: Repo.preload(tree, :picks)
end
