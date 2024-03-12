defmodule FruitPickerWeb.AgencyView do
  use FruitPickerWeb, :view

  import Scrivener.HTML

  alias FruitPicker.Partners.Agency
  alias FruitPickerWeb.{PickView, SharedView}

  def hours_options do
    [
      {"12:00 AM", "00:00:00"},
      {"12:30 AM", "00:30:00"},
      {"1:00 AM", "01:00:00"},
      {"1:30 AM", "01:30:00"},
      {"2:00 AM", "02:00:00"},
      {"2:30 AM", "02:30:00"},
      {"3:00 AM", "03:00:00"},
      {"3:30 AM", "03:30:00"},
      {"4:00 AM", "04:00:00"},
      {"4:30 AM", "04:30:00"},
      {"5:00 AM", "05:00:00"},
      {"5:30 AM", "05:30:00"},
      {"6:00 AM", "06:00:00"},
      {"6:30 AM", "06:30:00"},
      {"7:00 AM", "07:00:00"},
      {"7:30 AM", "07:30:00"},
      {"8:00 AM", "08:00:00"},
      {"8:30 AM", "08:00:00"},
      {"9:00 AM", "09:00:00"},
      {"9:30 AM", "09:30:00"},
      {"10:00 AM", "10:00:00"},
      {"10:30 AM", "10:30:00"},
      {"11:00 AM", "11:00:00"},
      {"11:30 AM", "11:30:00"},
      {"12:00 PM", "12:00:00"},
      {"12:30 PM", "12:30:00"},
      {"1:00 PM", "13:00:00"},
      {"1:30 PM", "13:30:00"},
      {"2:00 PM", "14:00:00"},
      {"2:30 PM", "14:30:00"},
      {"3:00 PM", "15:00:00"},
      {"3:30 PM", "15:30:00"},
      {"4:00 PM", "16:00:00"},
      {"4:30 PM", "16:30:00"},
      {"5:00 PM", "17:00:00"},
      {"5:30 PM", "17:30:00"},
      {"6:00 PM", "18:00:00"},
      {"6:30 PM", "18:30:00"},
      {"7:00 PM", "19:00:00"},
      {"7:30 PM", "19:30:00"},
      {"8:00 PM", "20:00:00"},
      {"8:30 PM", "20:30:00"},
      {"9:00 PM", "21:00:00"},
      {"9:30 PM", "21:30:00"},
      {"10:00 PM", "22:00:00"},
      {"10:30 PM", "22:30:00"},
      {"11:00 PM", "23:00:00"},
      {"11:30 PM", "23:30:00"},
    ]
  end

  def fruit(%Agency{} = agency) do
    [
      %{
        name: "Sweet Cherries",
        accepting: agency.accepting_sweet_cherries,
      },
      %{
        name: "Sour Cherries",
        accepting: agency.accepting_sour_cherries,
      },
      %{
        name: "Serviceberries",
        accepting: agency.accepting_serviceberries,
      },
      %{
        name: "Mulberries",
        accepting: agency.accepting_mulberries,
      },
      %{
        name: "Apricots",
        accepting: agency.accepting_apricots,
      },
      %{
        name: "Crabapples",
        accepting: agency.accepting_crabapples,
      },
      %{
        name: "Plums",
        accepting: agency.accepting_plums,
      },
      %{
        name: "Apples",
        accepting: agency.accepting_apples,
      },
      %{
        name: "Pears",
        accepting: agency.accepting_pears,
      },
      %{
        name: "Grapes",
        accepting: agency.accepting_grapes,
      },
      %{
        name: "Elderberries",
        accepting: agency.accepting_elderberries,
      },
      %{
        name: "Gingko",
        accepting: agency.accepting_gingko,
      },
      %{
        name: "Black Walnuts",
        accepting: agency.accepting_black_walnuts,
      },
      %{
        name: "Quince",
        accepting: agency.accepting_quince,
      },
      %{
        name: "Pawpaw",
        accepting: agency.accepting_pawpaw,
      },
    ]
  end

  def fruit_accepted(%Agency{} = agency) do
    Enum.filter(fruit(agency), fn fruit -> fruit.accepting == true end)
  end

  def today_class(weekday) do
    if weekday == Date.utc_today |> Date.day_of_week, do: "active"
   end
end
