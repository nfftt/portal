defmodule FruitPicker.Tasks.Accounts do
  @moduledoc """
  Scheduled job functions for fetching lat/long for locations.
  """

  @shortdoc "Update lat/long for agencies, properties, equipment sets"

  require Logger

  alias FruitPicker.Repo
  alias FruitPicker.Accounts.Property
  alias FruitPicker.Partners.Agency
  alias FruitPicker.Inventory.EquipmentSet

  @base_url "https://api.mapbox.com/geocoding/v5/mapbox.places/"

  def update_all() do
    update_agencies()
    update_properties()
    update_equipment_sets()
  end

  def update_agencies do
    Agency
    |> Repo.all()
    |> Enum.each(fn ag ->
      address = "#{ag.address} Toronto"

      latlong =
        address
        |> fetch_coordinates!()
        |> get_lat_long!()

      update_record!(%Agency{}, ag, latlong)
    end)
  end

  def update_properties do
    Property
    |> Repo.all()
    |> Enum.each(fn prop ->
      address = "#{prop.address_street} #{prop.address_city} #{prop.address_province}"

      latlong =
        address
        |> fetch_coordinates!()
        |> get_lat_long!()

      update_record!(%Property{}, prop, latlong)
    end)
  end

  def update_equipment_sets do
    EquipmentSet
    |> Repo.all()
    |> Enum.each(fn es ->
      address = "#{es.address} Toronto"

      latlong =
        address
        |> fetch_coordinates!()
        |> get_lat_long!()

      update_record!(%EquipmentSet{}, es, latlong)
    end)
  end

  defp fetch_coordinates!(address) do
    case HTTPoison.get(create_url(address)) do
      {:ok, response} ->
        if response.status_code == 200 do
          response
        else
          reason = "wrong response (#{response.status_code})"
          raise(reason)
        end

      {:error, %HTTPoison.Error{:reason => reason}} ->
        {:error, reason}
    end
  end

  defp get_lat_long!(%HTTPoison.Response{:body => body}) do
    # features.0.center.0 = longitude
    # features.0.center.1 = latitude
    %{"features" => features} = Jason.decode!(body)

    longitude =
      features
      |> Enum.at(0)
      |> Map.get("center")
      |> Enum.at(0)

    latitude =
      features
      |> Enum.at(0)
      |> Map.get("center")
      |> Enum.at(1)

    %{"longitude" => longitude, "latitude" => latitude}
  end

  defp update_record!(%Agency{}, record, latlong) do
    Logger.info("Updating agency '#{record.name}' with new coordinates.")

    record
    |> Agency.coordinates_changeset(latlong)
    |> Repo.update!()
  end

  defp update_record!(%EquipmentSet{}, record, latlong) do
    Logger.info("Updating equipment set '#{record.name}' with new coordinates.")

    record
    |> EquipmentSet.coordinates_changeset(latlong)
    |> Repo.update!()
  end

  defp update_record!(%Property{}, record, latlong) do
    Logger.info("Updating property with id ##{record.id} with new coordinates.")

    record
    |> Property.coordinates_changeset(latlong)
    |> Repo.update!()
  end

  defp create_url(search_term) do
    mapbox_api_key = Application.get_env(:fruit_picker, :mapbox_api_key)

    "#{@base_url}#{search_term}.json?country=ca&access_token=#{mapbox_api_key}"
  end
end
