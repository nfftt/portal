defmodule FruitPickerWeb.Admin.PersonView do
  use FruitPickerWeb, :view

  import Scrivener.HTML

  alias FruitPicker.Accounts.{Avatar, Person}
  alias FruitPicker.Accounts.Profile.ProvinceEnum
  alias FruitPicker.Policies
  alias FruitPickerWeb.Endpoint
  alias FruitPickerWeb.{PickView, SharedView}

  def full_name(%Person{} = person) do
    "#{person.first_name} #{person.last_name}"
  end

  def show_today() do
    Timex.now("America/Toronto")
    |> Timex.format!("%B %e, %Y", :strftime)
  end

  def friendly_date(date) do
    date
    |> Timex.format!("%B %e, %Y", :strftime)
  end

  def province_options do
    ProvinceEnum.__enum_map__()
  end

  def account_type(%Person{} = person) do
    case person.role do
      :admin ->
        "admin"
      :user ->
        if Enum.any?(friendly_permissions(person)) do
          Enum.map_join(friendly_permissions(person), ", ", &(&1[:name]))
        else
          "volunteer"
        end
      :agency ->
        "agency"
    end
  end

  def is_admin?(%Person{} = person) do
    person.role == :admin
  end

  def is_agency?(%Person{} = person) do
    person.role == :agency
  end

  def is_tree_owner?(%Person{} = person) do
    person.is_tree_owner
  end

  def is_lead_picker?(%Person{} = person) do
    person.is_lead_picker
  end

  def is_picker?(%Person{} = person) do
    person.is_picker
  end

  def friendly_permissions(%Person{} = person) do
    Enum.filter(permissions_list(person), fn person -> person.check == true end)
  end

  defp permissions_list(%Person{} = person) do
    [
      %{
        name: "picker",
        check: person.is_picker
      },
      %{
        name: "lead picker",
        check: person.is_lead_picker
      },
      %{
        name: "tree owner",
        check: person.is_tree_owner
      }
    ]
  end

  defdelegate avatar_url(person), to: SharedView
  defdelegate avatar_url(person, version), to: SharedView
end
