defmodule FruitPicker.Repo.Migrations.AddPropertiesAndTrees do
  use Ecto.Migration

  def change do
    create table(:properties) do
      add(:my_role, :string)
      add(:address_street, :string)
      add(:address_closest_intersection, :string)
      add(:address_city, :string)
      add(:address_postal_code, :string)
      add(:address_province, :string)
      add(:address_country, :string)
      add(:latlong, :string)
      add(:ladder_provided, :boolean)
      add(:tree_owner_takes, :string)
      add(:notes, :text)
      add(:person_id, references(:people, on_delete: :delete_all), null: false)

      timestamps()
    end

    create index(:properties, [:person_id])

    create table(:trees) do
      add(:nickname, :string)
      add(:is_active, :boolean, default: true)
      add(:pickable_this_year, :boolean)
      add(:unpickable_reason, :text) # TODO: enum?
      add(:type, :string)
      add(:fruit_variety, :string)
      add(:height, :string) # TODO: enum?
      add(:earliest_ripening_date, :date)
      add(:year_planted, :string) # TODO: enum?
      add(:tree_pruned_frequency, :string) # TODO: enum?
      add(:is_tree_sprayed_or_treated, :boolean)

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

      add(:property_id, references(:properties), null: false)

      timestamps()
    end

    create index(:trees, [:property_id, :nickname])

    alter table(:people) do
      add(:property_id, references(:properties))
    end
  end
end
