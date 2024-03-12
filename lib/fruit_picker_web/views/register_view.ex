defmodule FruitPickerWeb.RegisterView do
  use FruitPickerWeb, :view

  alias FruitPicker.Accounts.Person
  alias FruitPicker.Accounts.Profile.ProvinceEnum

  def province_options do
    ProvinceEnum.__enum_map__()
  end
end
