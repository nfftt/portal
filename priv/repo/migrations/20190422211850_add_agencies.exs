defmodule FruitPicker.Repo.Migrations.AddAgencies do
  use Ecto.Migration

  def change do
    create table(:agencies) do
      add(:name, :string)
      add(:address, :string)
      add(:closest_intersection, :string)
      add(:latlong, :string)
      add(:contact_name, :string)
      add(:contact_number, :string)
      add(:secondary_contact_number, :string)
      add(:is_accepting_fruit, :boolean, default: true)
      add(:special_instructions, :text)

      # wanted fruit
      add(:accepting_sweet_cherries, :boolean, default: false)
      add(:accepting_sour_cherries, :boolean, default: false)
      add(:accepting_serviceberries, :boolean, default: false)
      add(:accepting_mulberries, :boolean, default: false)
      add(:accepting_apricots, :boolean, default: false)
      add(:accepting_crabapples, :boolean, default: false)
      add(:accepting_plums, :boolean, default: false)
      add(:accepting_apples, :boolean, default: false)
      add(:accepting_pears, :boolean, default: false)
      add(:accepting_grapes, :boolean, default: false)
      add(:accepting_elderberries, :boolean, default: false)
      add(:accepting_gingko, :boolean, default: false)
      add(:accepting_black_walnuts, :boolean, default: false)
      add(:accepting_quince, :boolean, default: false)
      add(:accepting_pawpaw, :boolean, default: false)

      # scheduling fields
      add(:sunday_hours_start, :time)
      add(:sunday_hours_end, :time)
      add(:sunday_closed, :boolean, default: false)
      add(:monday_hours_start, :time)
      add(:monday_hours_end, :time)
      add(:monday_closed, :boolean, default: false)
      add(:tuesday_hours_start, :time)
      add(:tuesday_hours_end, :time)
      add(:tuesday_closed, :boolean, default: false)
      add(:wednesday_hours_start, :time)
      add(:wednesday_hours_end, :time)
      add(:wednesday_closed, :boolean, default: false)
      add(:thursday_hours_start, :time)
      add(:thursday_hours_end, :time)
      add(:thursday_closed, :boolean, default: false)
      add(:friday_hours_start, :time)
      add(:friday_hours_end, :time)
      add(:friday_closed, :boolean, default: false)
      add(:saturday_hours_start, :time)
      add(:saturday_hours_end, :time)
      add(:saturday_closed, :boolean, default: false)

      timestamps()
    end

    create unique_index(:agencies, [:name])
  end
end
