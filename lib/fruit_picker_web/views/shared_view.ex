defmodule FruitPickerWeb.SharedView do
  use FruitPickerWeb, :view

  alias FruitPicker.Accounts.{Avatar, Person}
  alias FruitPicker.Accounts.Profile.ProvinceEnum

  alias FruitPicker.Activities.{
    Pick,
    PickReport
  }

  alias FruitPickerWeb.Endpoint

  def province_options do
    ProvinceEnum.__enum_map__()
  end

  def full_name(%Person{} = person) do
    "#{person.first_name} #{person.last_name}"
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

  def friendly_truthy(value) do
    if value, do: "Yes", else: "No"
  end

  def friendly_permissions(%Person{} = person) do
    Enum.filter(permissions_list(person), fn person -> person.check == true end)
  end

  def friendly_date(date) do
    date
    # |> Timex.shift(hours: -4)
    |> Timex.format!("%B %e, %Y", :strftime)
  end

  def short_date(date) do
    date
    |> Timex.format!("%Y-%m-%d", :strftime)
  end

  def twelve_hour_time(time) when not is_nil(time) do
    Timex.format!(time, "{h12}:{m} {AM}")
  end

  def twelve_hour_time(time) do
    ""
  end

  def account_type(%Person{} = person) do
    case person.role do
      :admin ->
        "admin"

      :user ->
        if Enum.any?(friendly_permissions(person)) do
          Enum.map_join(friendly_permissions(person), ", ", & &1[:name])
        else
          "volunteer"
        end

      :agency ->
        "agency"
    end
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

  def get_lat(resource) do
    if resource.latitude do
      resource.latitude
    else
      ""
    end
  end

  def get_long(resource) do
    if resource.longitude do
      resource.longitude
    else
      ""
    end
  end

  def friendly_pounds(amount) when is_nil(amount) do
    0
  end

  def friendly_pounds(amount) do
    if amount == 0 do
      0
    else
      amount
      |> Float.round()
      |> Kernel.trunc()
    end
  end

  def friendly_percent(amount) do
    if amount == 0 do
      "0 %"
    else
      "#{Float.round(amount, 2)} %"
    end
  end

  def report_has_issue?(%PickReport{} = report) do
    report.has_equipment_set_issue or
      not report.has_fruit_delivered_to_agency or
      report.has_issues_on_site
  end

  def pick_closest_intersection(%Pick{} = pick) do
    if pick.requester.property do
      pick.requester.property.address_closest_intersection
    else
      ""
    end
  end

  defp gravatar_url(nil, _version), do: "https://www.gravatar.com/avatar"
  defp gravatar_url(email, version) do
    size =
      case version do
        :small -> 100
        :medium -> 300
        _else -> 100
      end

    hash =
      email
      |> String.trim()
      |> String.downcase()
      |> :erlang.md5()
      |> Base.encode16(case: :lower)

    "https://secure.gravatar.com/avatar/#{hash}.jpg?s=#{size}&d=mm"
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
end
