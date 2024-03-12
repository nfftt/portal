defmodule FruitPicker.PartnersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FruitPicker.Partners` context.
  """
  alias FruitPicker.Partners

  @doc """
  Generate an agency.
  """
  def agency_fixture(attrs \\ %{}) do
    {:ok, agency} =
      attrs
      |> Enum.into(%{
        "name" => Faker.Company.name(),
        "address" => Faker.Address.street_address(),
        "closest_intersection" => "#{Faker.Address.street_name()} and #{Faker.Address.street_name()}",
        "contact_name" => Faker.Name.name(),
        "contact_email" => Faker.Internet.email(),
        "contact_number" => Faker.Phone.EnUs.phone(),
        "sunday_hours_start" => ~T[00:00:00],
        "sunday_hours_end" => ~T[23:59:59],
        "monday_hours_start" => ~T[00:00:00],
        "monday_hours_end" => ~T[23:59:59],
        "tuesday_hours_start" => ~T[00:00:00],
        "tuesday_hours_end" => ~T[23:59:59],
        "wednesday_hours_start" => ~T[00:00:00],
        "wednesday_hours_end" => ~T[23:59:59],
        "thursday_hours_start" => ~T[00:00:00],
        "thursday_hours_end" => ~T[23:59:59],
        "friday_hours_start" => ~T[00:00:00],
        "friday_hours_end" => ~T[23:59:59],
        "saturday_hours_start" => ~T[00:00:00],
        "saturday_hours_end" => ~T[23:59:59],

        "is_accepting_fruit" => true,
        "accepting_sweet_cherries" => true,
        "accepting_sour_cherries" => true,
        "accepting_serviceberries" => true,
        "accepting_mulberries" => true,
        "accepting_apricots" => true,
        "accepting_crabapples" => true,
        "accepting_plums" => true,
        "accepting_apples" => true,
        "accepting_pears" => true,
        "accepting_grapes" => true,
        "accepting_elderberries" => true,
        "accepting_gingko" => true,
        "accepting_black_walnuts" => true,
        "accepting_quince" => true,
        "accepting_pawpaw" => true,
      })
      |> Partners.create_agency()

      agency
  end
end
