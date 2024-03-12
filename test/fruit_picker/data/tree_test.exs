defmodule FruitPicker.Accounts.TreeTest do
  @moduledoc false

  use FruitPicker.DataCase

  alias FruitPicker.Accounts.Tree

  @valid_attrs %{
    nickname: "Peter",
    pickable_this_year: true,
    type: "Apple",
    fruit_variety: "Green Apple",
    height: "1 Story",
    earliest_ripening_date: ~D[2019-06-01],
    year_planted: "2019",
    tree_pruned_frequency: "annually",
    is_tree_sprayed_or_treated: "No",
    receive_mulching: false,
    receive_watering: false,
    receive_pruning: false,
    receive_other: "",
    has_broken_branches: false,
    has_limbs_missing_bark: false,
    has_bare_branches_no_growth: false,
    has_rotten_wood: false,
    has_large_trunk_cracks: false,
    has_mushrooms_at_base: false,
    has_trunk_strong_lean: false,
    has_no_issues: false,
    pests_on_tree: false,
    pests_yellow_spots_on_leaves: false,
    pests_swollen_twisted_branches: false,
    pests_leaves_small_dark_spots_holes: false,
    pests_brown_spots_fruit_scabs: false,
    pests_rotting_fruit_on_branches: false,
    pests_powdery_mildew: false,
    pests_dried_out_leaves_withering_fruit: false,
    pests_oozing_sappy_liquid: false,
    pests_none: false
  }
  @valid_edit_attrs %{
    nickname: "Peter",
    pickable_this_year: true,
    type: "Apple",
    fruit_variety: "Green Apple",
    height: "1 Story",
    earliest_ripening_date: ~D[2019-06-01],
    year_planted: "2019",
    tree_pruned_frequency: "annually",
    is_tree_sprayed_or_treated: "No"
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Tree.changeset(%Tree{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Tree.changeset(%Tree{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "edit_changeset with valid attributes" do
    changeset = Tree.edit_changeset(%Tree{}, @valid_edit_attrs)
    assert changeset.valid?
  end

  test "edit_changeset with invalid attributes" do
    changeset = Tree.edit_changeset(%Tree{}, @invalid_attrs)
    refute changeset.valid?
  end
end
