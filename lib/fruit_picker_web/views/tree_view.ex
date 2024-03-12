defmodule FruitPickerWeb.TreeView do
  use FruitPickerWeb, :view

  alias FruitPicker.Activities.Pick

  alias FruitPicker.Accounts.{
    Tree,
    TreeSnapshot
  }

  def friendly_date(date) do
    date
    |> Timex.format!("%B %e, %Y", :strftime)
  end

  def tree_receives(%Tree{} = tree) do
    if Enum.any?(tree.snapshots) do
      items =
        tree.snapshots
        |> Enum.sort_by(&Map.fetch!(&1, :inserted_at), &>=/2)
        |> Enum.at(0)

      Enum.filter(tree_receives_list(items), fn tree -> tree.receives == true end)
    else
      Enum.filter(tree_receives_list(tree), fn tree -> tree.receives == true end)
    end
  end

  defp tree_receives_list(tree) do
    [
      %{
        name: "Mulching",
        receives: tree.receive_mulching
      },
      %{
        name: "Watering",
        receives: tree.receive_watering
      },
      %{
        name: "Pruning",
        receives: tree.receive_pruning
      },
      %{
        name: tree.receive_other,
        receives: if(tree.receive_other == "", do: true, else: false)
      }
    ]
  end

  def tree_has(%Tree{} = tree) do
    if Enum.any?(tree.snapshots) do
      items =
        tree.snapshots
        |> Enum.sort_by(&Map.fetch!(&1, :inserted_at), &>=/2)
        |> Enum.at(0)

      Enum.filter(tree_has_list(items), fn tree -> tree.has == true end)
    else
      Enum.filter(tree_has_list(tree), fn tree -> tree.has == true end)
    end
  end

  defp tree_has_list(tree) do
    [
      %{
        name: "Broken or hanging branches",
        has: tree.has_broken_branches
      },
      %{
        name: "Limbs with missing bark",
        has: tree.has_limbs_missing_bark
      },
      %{
        name: "Bare branches with no new leaf or bud growth",
        has: tree.has_bare_branches_no_growth
      },
      %{
        name: "Cavities or rotten wood along the trunk or in major branches",
        has: tree.has_rotten_wood
      },
      %{
        name: "Deep, large cracks in the trunk",
        has: tree.has_large_trunk_cracks
      },
      %{
        name: "Mushrooms present at base of tree",
        has: tree.has_mushrooms_at_base
      },
      %{
        name: "Trunk as a strong lean",
        has: tree.has_trunk_strong_lean
      },
      %{
        name: "Has no issues",
        has: tree.has_no_issues
      }
    ]
  end

  def tree_pests(%Tree{} = tree) do
    if Enum.any?(tree.snapshots) do
      items =
        tree.snapshots
        |> Enum.sort_by(&Map.fetch!(&1, :inserted_at), &>=/2)
        |> Enum.at(0)

      Enum.filter(tree_pests_list(items), fn tree -> tree.pest == true end)
    else
      Enum.filter(tree_pests_list(tree), fn tree -> tree.pest == true end)
    end
  end

  defp tree_pests_list(tree) do
    [
      %{
        name: "Pests on the tree (beetles, ants, aphids, mites, etc.)",
        pest: tree.pests_on_tree
      },
      %{
        name: "Yellow of orange coloured spots on the leaves",
        pest: tree.pests_yellow_spots_on_leaves
      },
      %{
        name: "Twigs or branches are swollen, black, and twisted",
        pest: tree.pests_swollen_twisted_branches
      },
      %{
        name: "Tree leaves covered in small dark coloured spots, which turn into holes",
        pest: tree.pests_leaves_small_dark_spots_holes
      },
      %{
        name: "Dark, brown spots on fruit that harden into scabs",
        pest: tree.pests_brown_spots_fruit_scabs
      },
      %{
        name: "Fruit and leaves appear to be rotting or decomposing on branches",
        pest: tree.pests_rotting_fruit_on_branches
      },
      %{
        name: "Powdery mildew on fruit or leaves",
        pest: tree.pests_powdery_mildew
      },
      %{
        name: "Leaves are dried out, and have turned black or brown; withering fruit",
        pest: tree.pests_dried_out_leaves_withering_fruit
      },
      %{
        name: "Branches or bark are oozing amber-coloured sappy liquid",
        pest: tree.pests_oozing_sappy_liquid
      },
      %{
        name: "No evidence of pests or disease",
        pest: tree.pests_none
      }
    ]
  end

  def tree_type_options do
    [
      {"Apple", "apple"},
      {"Apricot", "apricot"},
      {"Sweet Cherry", "sweet cherry"},
      {"Sour Cherry", "sour cherry"},
      {"Crabapple", "crabapple"},
      {"Elderberry", "elderberry"},
      {"Grape", "grape"},
      {"Mulberry", "mulberry"},
      {"Peach", "peach"},
      {"Pear", "pear"},
      {"Plum", "plum"},
      {"Quince", "quince"},
      {"Red Currant", "red currant"},
      {"Serviceberry (Saskatoon Berry)", "serviceberry"},
      {"Walnut", "walnut"}
    ]
  end

  def tree_height_options do
    [
      {"Less than 1 storey (< 3 metres)", "Less than 1 storey (< 3 metres)"},
      {"1-2 storeys (3-6 metres)", "1-2 storeys (3-6 metres)"},
      {"2-3 storeys (6-9 metres)", "2-3 storeys (6-9 metres)"},
      {"3 storeys (> 9 metres)", "3 storeys (> 9 metres)"}
    ]
  end

  def tree_planted_options do
    [
      {"5 years ago", "5 years ago"},
      {"5-10 years ago", "5-10 years ago"},
      {"11-20 years ago", "11-20 years ago"},
      {"21-30 years ago", "21-30 years ago"},
      {"31+ years ago", "31+ years ago"}
    ]
  end

  def tree_pruned_options do
    [
      {"Never", "Never"},
      {"Every Year", "Every Year"},
      {"Every 2-3 years", "Every 2-3 years"},
      {"Rarely (every 3+ years)", "Rarely (every 3+ years)"}
    ]
  end

  def tree_sprayed_options do
    [
      {"No", "No"},
      {"Yes, with a common pesticide or insecticide",
       "Yes, with a common pesticide or insecticide"},
      {"Yes, but it's non-toxic and/or organic", "Yes, but it's non-toxic and/or organic"}
    ]
  end

  def deactivate_options do
    [
      {"My tree no longer produces fruit", "My tree no longer produces fruit"},
      {"My tree died", "My tree died"},
      {"I decided to cut down my tree", "I decided to cut down my tree"},
      {"I moved properties", "I moved properties"},
      {"I am no longer interested in participating in this program",
       "I am no longer interested in participating in this program"}
    ]
  end

  def tree_type_ripeness_guide(%Tree{} = tree) do
    type =
      case tree.type do
        "sweet cherry" ->
          "sweet-cherries"

        "sour cherry" ->
          "sour-cherries"

        "mulberry" ->
          "mulberries"

        "serviceberry" ->
          "serviceberries"

        "apple" ->
          "apples"

        "plum" ->
          "plums"

        "crabapple" ->
          "crabapples"

        "apricot" ->
          "apricots"

        "elderberry" ->
          "elderberries"

        "grape" ->
          "grapes"

        "pear" ->
          "pears"

          "ginkgo" ->
            "ginkgo"

          "quince" ->
          "quince"

        "walnut" ->
          "black-walnut"

        "pawpaw" ->
          "pawpaw"

        _ ->
          "sweet-cherries"
      end

    generate_ripeness_guide_url(type)
  end

  defp generate_ripeness_guide_url(type) do
    "https://notfarfromthetree.org/fruit/#{type}/"
  end
end
