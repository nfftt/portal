defmodule FruitPickerWeb.ProfileView do
  use FruitPickerWeb, :view

  alias FruitPicker.Accounts.Person
  alias FruitPicker.Accounts.Profile.ProvinceEnum
  alias FruitPickerWeb.SharedView

  def friendly_date(date) do
    date
    |> Timex.format!("%B %e, %Y", :strftime)
  end

  def province_options do
    ProvinceEnum.__enum_map__()
  end

  def stripe_role(person) do
    if person.is_tree_owner do
      "tree_owner"
    else
      "picker"
    end
  end

  def payment_details(person) do
    cond do
      person.role in [:admin, :agency] ->
        "No Payment (Partnership)"
      person.is_tree_owner ->
        "Paid $30.00 / 1-Year Commitment"
      person.is_picker ->
        "Paid $10.00 / 1-Year Commitment"
      true ->
        ""
    end
  end
end
