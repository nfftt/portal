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

  def avatar_path(person, version) do
    {person.avatar, person}
    |> Avatar.url(version, signed: true)
    |> String.replace_leading("/priv", "")
  end

  def avatar_url(person), do: avatar_url(person, :small)
  def avatar_url(person, version) do
    if person.avatar do
      url = avatar_path(person, version)

      if String.starts_with?(url, "/") do
        Routes.static_url(Endpoint, avatar_path(person, version))
      else
        url
      end
    else
      gravatar_url(person.email, version)
    end
  end

  defp gravatar_url(nil, _version), do: "https://www.gravatar.com/avatar"
  defp gravatar_url(email, version) do
    size = case version do
             :small  -> 100
             :medium -> 300
             _else   -> 100
           end

    hash = email
    |> String.trim
    |> String.downcase
    |> :erlang.md5
    |> Base.encode16(case: :lower)

    "https://secure.gravatar.com/avatar/#{hash}.jpg?s=#{size}&d=mm"
  end
end
