defmodule FruitPicker.Tasks.Coordinates do
  @moduledoc """
  Scheduled job functions for fetching lat/long for locations.
  """

  @shortdoc "Update lat/long for agencies, properties, equipment sets"

  require Logger
  import Ecto.Query

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
    |> where([a], is_nil(a.coordinates_updated_at))
    |> or_where([a], a.updated_at > a.coordinates_updated_at)
    |> Repo.all()
    |> Enum.each(fn ag ->
      address = "#{ag.address} Toronto Ontario"

      latlong =
        address
        |> fetch_coordinates()
        |> get_lat_long()

      update_record(%Agency{}, ag, latlong)
    end)
  end

  def update_properties do
    Property
    |> where([a], is_nil(a.coordinates_updated_at))
    |> or_where([a], a.updated_at > a.coordinates_updated_at)
    |> Repo.all()
    |> Enum.each(fn prop ->
      address =
        "#{prop.address_street} #{prop.address_city || "Toronto"} #{
          prop.address_province || "Ontario"
        }"

      latlong =
        address
        |> fetch_coordinates()
        |> get_lat_long()

      update_record(%Property{}, prop, latlong)
    end)
  end

  def update_equipment_sets do
    EquipmentSet
    |> where([a], is_nil(a.coordinates_updated_at))
    |> or_where([a], a.updated_at > a.coordinates_updated_at)
    |> Repo.all()
    |> Enum.each(fn es ->
      address = "#{es.address} Toronto Ontario"

      latlong =
        address
        |> fetch_coordinates()
        |> get_lat_long()

      update_record(%EquipmentSet{}, es, latlong)
    end)
  end

  defp fetch_coordinates(address) do
    case HTTPoison.get(create_url(address)) do
      {:ok, response} ->
        if response.status_code == 200 do
          response
        else
          Logger.info("Wrong response from Mapbox (#{response.status.code})")
          Logger.info("Wrong response from Mapbox (#{response.status.code})")
          nil
        end

      {:error, %HTTPoison.Error{:reason => reason}} ->
        Logger.info("Wrong response from Mapbox (#{reason})")
        Logger.info("Wrong response from Mapbox (#{reason})")
        nil
    end
  end

  defp get_lat_long(%HTTPoison.Response{:body => body}) do
    # features.0.center.0 = longitude
    # features.0.center.1 = latitude
    %{"features" => features} = Jason.decode!(body)

    entry = Enum.at(features, 0)

    if is_nil(entry) do
      Logger.info("Nothing found")
      %{"longitude" => nil, "latitude" => nil}
    else
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
  end

  defp get_lat_long(nil), do: nil

  defp update_record(%Agency{}, record, %{"longitude" => nil, "latitude" => nil}) do
    Logger.info("Could not update agency '#{record.name}', latlong is nil.")
  end

  defp update_record(%Agency{}, record, latlong) do
    changeset = Agency.coordinates_changeset(record, latlong)

    case Repo.update(changeset) do
      {:ok, _agency} ->
        Logger.info("Updating agency '#{record.name}' with new coordinates.")
        :ok

      {:error, _error} ->
        Logger.info("Could not update agency '#{record.name}' with new coordinates.")
        nil
    end
  end

  defp update_record(%EquipmentSet{}, record, %{"longitude" => nil, "latitude" => nil}) do
    Logger.info("Could not update equipment set '#{record.name}', latlong is nil.")
  end

  defp update_record(%EquipmentSet{}, record, latlong) do
    changeset = EquipmentSet.coordinates_changeset(record, latlong)

    case Repo.update(changeset) do
      {:ok, _set} ->
        Logger.info("Updating equipment set '#{record.name}' with new coordinates.")
        :ok

      {:error, _error} ->
        Logger.info("Could not update equipment set '#{record.name}' with new coordinates.")
        nil
    end
  end

  defp update_record(%Property{}, record, %{"longitude" => nil, "latitude" => nil}) do
    Logger.info("Could not update property '#{record.name}', latlong is nil.")
  end

  defp update_record(%Property{}, record, latlong) do
    changeset = Property.coordinates_changeset(record, latlong)

    case Repo.update(changeset) do
      {:ok, _property} ->
        Logger.info("Updating property with id ##{record.id} with new coordinates.")

      {:error, _error} ->
        Logger.info("Could not update property with id ##{record.id} with new coordinates.")
    end
  end

  defp create_url(search_term) do
    mapbox_api_key = Application.get_env(:fruit_picker, :mapbox_api_key)

    "#{@base_url}#{URI.encode(search_term)}.json?country=ca&access_token=#{mapbox_api_key}"
  end
end
