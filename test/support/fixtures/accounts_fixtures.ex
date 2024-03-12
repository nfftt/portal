defmodule FruitPicker.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FruitPicker.Accounts` context.
  """
  alias FruitPicker.Accounts

  @doc """
  Generate a person.
  """
  def person_fixture(attrs \\ %{}, role) do
    {:ok, person} =
      attrs
      |> Enum.into(%{
        "email" => Faker.Internet.email(),
        "number_picks_trigger_waitlist" => 5,
        "first_name" => Faker.Person.first_name(),
        "last_name" => Faker.Person.last_name(),
        "is_picker" => true,
        "password" => "pass1234",
        "password_confirmation" => "pass1234",
        "profile" => %{
          "phone_number" => "416-555-5555",
          "secondary_phone_number" => "416-555-5555",
          "address_street" => "123 Fake St.",
          "address_postal_code" => "M5V 0K2",
          "address_city" => "Toronto",
          "address_province" => "Ontario"
        }
      })
      |> Accounts.admin_create_person(role)

    person
  end

  def property_fixture(attrs \\ %{}, tree_owner) do
    {:ok, property} =
      attrs
      |> Enum.into(%{
        "my_role" => "Property Owner",
        "address_street" => "123 Fake St.",
        "address_postal_code" => "M5V 0K2",
        "address_city" => "Toronto",
        "address_closest_intersection" => "Bloor and Fake",
        "notes" => "bla"
      })
      |> Accounts.create_property(tree_owner)

    property
  end

  def tree_fixture(attrs \\ %{}, property) do
    {:ok, tree} =
      attrs
      |> Enum.into(%{
        "pickable_this_year" => true,
        "type" => "Apple",
        "height" => "Less than 1 storey (< 3 metres)",
        "earliest_ripening_date" => Date.utc_today(),
        "year_planted" => "2011",
        "tree_pruned_frequency" => "Never",
        "is_tree_sprayed_or_treated" => "No",
        "receive_mulching" => true,
        "receive_watering" => true,
        "receive_pruning" => false,
        "has_broken_branches" => false,
        "has_limbs_missing_bark" => false,
        "has_bare_branches_no_growth" => false,
        "has_rotten_wood" => false,
        "has_large_trunk_cracks" => false,
        "has_mushrooms_at_base" => true,
        "has_trunk_strong_lean" => true,
        "has_no_issues" => true,
        "pests_on_tree" => false,
        "pests_yellow_spots_on_leaves" => false,
        "pests_swollen_twisted_branches" => false,
        "pests_leaves_small_dark_spots_holes" => false,
        "pests_brown_spots_fruit_scabs" => false,
        "pests_rotting_fruit_on_branches" => false,
        "pests_powdery_mildew" => false,
        "pests_dried_out_leaves_withering_fruit" => false,
        "pests_oozing_sappy_liquid" => false,
        "pests_none" => true
      })
      |> Accounts.create_tree(property)

    tree
  end
end
