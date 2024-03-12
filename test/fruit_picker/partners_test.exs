defmodule FruitPicker.PartnersTest do
  use FruitPicker.DataCase

  alias FruitPicker.PartnersFixtures
  alias FruitPicker.Partners

  test "list_agencies/0" do
    agency = PartnersFixtures.agency_fixture()

    assert [a] = Partners.list_agencies()

    # Note we don't get *all* the fields
    assert a.id == agency.id
    assert a.name == agency.name
  end

  test "list_allagencies/0" do
    agency = PartnersFixtures.agency_fixture()

    # this gets all the fields
    assert = Partners.list_all_agencies() == [agency]
  end
end
