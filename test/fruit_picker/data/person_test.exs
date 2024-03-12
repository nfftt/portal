defmodule FruitPicker.Accounts.PersonTest do
  use FruitPicker.DataCase

  alias FruitPicker.Accounts.Person

  @valid_attrs %{
    first_name: "Joe",
    last_name: "Picker",
    email: "joe@example.com",
    password: "password",
    password_confirmation: "password",
    accepts_consent_picker: true,
    accepts_portal_communications: true
  }
  @invalid_attrs %{}

  test "register_changeset with valid attributes" do
    changeset = Person.register_changeset(%Person{}, @valid_attrs, "fruit_picker")
    assert changeset.valid?
  end

  test "register_changeset with invalid attributes" do
    changeset = Person.register_changeset(%Person{}, @invalid_attrs, "")
    refute changeset.valid?
  end
end
