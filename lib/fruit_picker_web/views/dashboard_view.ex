defmodule FruitPickerWeb.DashboardView do
  use FruitPickerWeb, :view
  use Timex

  alias FruitPicker.Activities.Pick
  alias FruitPicker.Accounts.{Person, Tree}
  alias FruitPickerWeb.{PickView, SharedView}

  def show_today() do
    Timex.now("America/Toronto")
    |> Timex.format!("%B %e, %Y", :strftime)
  end

  def friendly_date(date) do
    date
    |> Timex.format!("%B %e, %Y", :strftime)
  end

  def picker?(%Person{} = person) do
    person.is_picker
  end

  def lead_picker?(%Person{} = person) do
    person.is_lead_picker
  end

  def tree_owner?(%Person{} = person) do
    person.is_tree_owner
  end

  def agency?(%Person{} = person) do
    person.role == :agency
  end
end
