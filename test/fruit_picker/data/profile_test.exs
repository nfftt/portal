defmodule FruitPicker.Accounts.ProfileTest do
  use FruitPicker.DataCase

  alias FruitPicker.Accounts.Profile

  @valid_attrs %{
    phone_number: "555-5555",
    address_street: "123 Fake Street",
    address_city: "Toronto",
    address_province: "Ontario",
    address_postal_code: "M1N 0B3",
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Profile.changeset(%Profile{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Profile.changeset(%Profile{}, @invalid_attrs)
    refute changeset.valid?
  end
end
