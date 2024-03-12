defmodule FruitPicker.Mailchimp do
  @default_api_version "3.0"
  @picker_list_id "ba8ffd9fe9"
  @tree_owner_list_id "a38b0cf0fb"
  @newsletter_list_id "c905930eed"

  @out_of_operating_area_segment_id "523"

  import Logger

  def add_fruit_tag_to_tree_owner(email, fruit_type) do
    if api_key! do
      url = tree_tag_url!(segment_id!(fruit_type))

      case FruitPicker.Mailchimp.HTTPClient.post(url, Jason.encode!(%{email_address: email})) do
        {:ok, response} ->
          case response.status_code do
            200 ->
              Logger.info("Successfully added #{email} to the mailchimp #{fruit_type} tag.")

            400 ->
              Logger.error(
                "Could not add #{email} to the mailchimp #{fruit_type} tag because they are already on it or are not on the tree owners audience list."
              )

            _ ->
              Logger.error(
                "There was a problem (#{response.status_code}) adding #{email} to the #{fruit_type} mailchimp tag."
              )
          end

        {:error, %HTTPoison.Error{:reason => reason}} ->
          Logger.error("There was a problem adding #{email} to the mailchimp tag. #{reason}")
      end
    else
      Logger.info("No Mailchimp API key, cannot add #{email} to #{fruit_type} tag.")
    end
  end

  def add_oooa_tag_to_tree_owner(email) do
    if api_key! do
      url = tree_tag_url!(@out_of_operating_area_segment_id)

      case FruitPicker.Mailchimp.HTTPClient.post(url, Jason.encode!(%{email_address: email})) do
        {:ok, response} ->
          case response.status_code do
            200 ->
              Logger.info(
                "Successfully added #{email} to the mailchimp out of operating segment."
              )

            400 ->
              Logger.error(
                "Could not add #{email} to the mailchimp out of operating area segment because they are already on it or are not on the tree owners audience list."
              )

            _ ->
              Logger.error(
                "There was a problem (#{response.status_code}) adding #{email} to the out of operating area mailchimp segment."
              )
          end

        {:error, %HTTPoison.Error{:reason => reason}} ->
          Logger.error("There was a problem adding #{email} to the mailchimp tag. #{reason}")
      end
    else
      Logger.info("No Mailchimp API key, cannot add #{email} to the ooaa segment.")
    end
  end

  def remove_oooa_tag_to_tree_owner(email) do
    if api_key! do
      url = remove_tree_tag_url!(@out_of_operating_area_segment_id, email)

      case FruitPicker.Mailchimp.HTTPClient.delete(url) do
        {:ok, response} ->
          case response.status_code do
            204 ->
              Logger.info(
                "Successfully removed #{email} to the mailchimp out of operating segment."
              )

            _ ->
              Logger.error(
                "There was a problem (#{response.status_code}) removing #{email} from the out of operating area mailchimp segment."
              )
          end

        {:error, %HTTPoison.Error{:reason => reason}} ->
          Logger.error("There was a problem adding #{email} to the mailchimp tag. #{reason}")
      end
    else
      Logger.info("No Mailchimp API key, cannot remove #{email} from the ooaa segment.")
    end
  end

  def subscribe(person, "fruit_picker") do
    if api_key! do
      add_to_audience(person, "#{root_endpoint!()}lists/#{@picker_list_id}/members")
    else
      Logger.info("No Mailchimp API key, cannot add #{person.email} to fruit picker list.")
    end
  end

  def subscribe(person, "tree_owner") do
    if api_key! do
      add_to_audience(person, "#{root_endpoint!()}lists/#{@tree_owner_list_id}/members")
    else
      Logger.info("No Mailchimp API key, cannot add #{person.email} to tree owner list.")
    end
  end

  def add_to_audience(person, url) do
    case FruitPicker.Mailchimp.HTTPClient.post(url, Jason.encode!(member_data!(person))) do
      {:ok, response} ->
        case response.status_code do
          200 ->
            Logger.info("Successfully added #{person.email} to the mailchimp audience.")

          400 ->
            Logger.error(
              "Could not add #{person.email} to the mailchimp audience because they are already on it."
            )

          _ ->
            Logger.error(
              "There was a problem (#{response.status_code}) adding #{person.email} to the mailchimp audience."
            )
        end

      {:error, %HTTPoison.Error{:reason => reason}} ->
        Logger.error(
          "There was a problem adding #{person.email} to the mailchimp audience. #{reason}"
        )
    end
  end

  defp member_data!(person) do
    %{
      email_address: person.email,
      status: :subscribed,
      merge_fields: %{
        FNAME: person.first_name,
        LNAME: person.last_name
      }
    }
  end

  def api_key!, do: Application.get_env(:fruit_picker, :mailchimp_api_key)

  @spec shard!() :: String.t() | no_return
  defp shard! do
    api_key!()
    |> String.split("-", parts: 2)
    |> Enum.at(1)
  end

  @spec api_version!() :: String.t()
  defp api_version!,
    do: Application.get_env(:fruit_picker, :mailchimp_api_version, @default_api_version)

  @spec root_endpoint!() :: String.t() | no_return
  defp root_endpoint! do
    "https://#{shard!()}.api.mailchimp.com/#{api_version!()}/"
  end

  # [
  #   %{id: 81, name: "Cherry Berry"},
  #   %{id: 85, name: "Stone Fruit"},
  #   %{id: 89, name: "Pear"},
  #   %{id: 93, name: "Apple Crabapple"},
  #   %{id: 101, name: "Grape"},
  #   %{id: 321, name: "Quince Walnut"},
  #   %{id: 461, name: "Moved"},
  #   %{id: 465, name: "Tree Diseased"},
  #   %{id: 473, name: "Tree Died"},
  #   %{id: 495, name: "Campaign MMA Unsubscribers"}
  # ]

  @spec segment_id!(String.t()) :: String.t()
  defp segment_id!(fruit_type) do
    case fruit_type do
      "apple" -> "93"
      "apricot" -> "85"
      "sweet cherry" -> "81"
      "ginkgo" -> "321"
      "sour cherry" -> "81"
      "crabapple" -> "93"
      "elderberry" -> "81"
      "grape" -> "101"
      "mulberry" -> "81"
      "peach" -> "85"
      "pear" -> "89"
      "plum" -> "85"
      "quince" -> "321"
      "red currant" -> "81"
      "serviceberry" -> "81"
      "walnut" -> "321"
      _ -> false
    end
  end

  @spec segment_id!(String.t()) :: String.t()
  defp tree_tag_url!(segment_id) do
    "#{root_endpoint!()}lists/#{@tree_owner_list_id}/segments/#{segment_id}/members"
  end

  defp remove_tree_tag_url!(segment_id, email) do
    subscriber_hash = :crypto.hash(:md5, email) |> Base.encode16()

    "#{root_endpoint!()}lists/#{@tree_owner_list_id}/segments/#{segment_id}/members/#{subscriber_hash}"
  end

  def list_tree_owner_segments() do
    case FruitPicker.Mailchimp.HTTPClient.get(list_tree_owner_segments_url) do
      {:ok, response} ->
        Jason.decode!(response.body)
        |> Map.get("segments")
        |> Enum.map(fn seg ->
          %{
            id: seg["id"],
            name: seg["name"],
            list_id: seg["list_id"],
            member_count: seg["member_count"]
          }
        end)
        |> IO.inspect()
    end
  end

  def list_tree_owner_tags() do
    case FruitPicker.Mailchimp.HTTPClient.get(list_tree_owner_tags_url) do
      {:ok, response} ->
        IO.puts("ok")

        Jason.decode!(response.body)
        |> Map.get("tags")
        |> Enum.map(fn seg ->
          %{
            list_id: seg["list_id"],
            name: seg["name"]
          }
        end)
        |> IO.inspect()
    end
  end

  defp list_tree_owner_segments_url() do
    "#{root_endpoint!()}lists/#{@tree_owner_list_id}/segments?count=100"
  end

  defp list_tree_owner_tags_url() do
    "#{root_endpoint!()}lists/#{@tree_owner_list_id}/tag-search?count=100"
  end

  def list_audiences() do
    case FruitPicker.Mailchimp.HTTPClient.get(audiences_url) do
      {:ok, response} ->
        IO.puts("ok")

        Jason.decode!(response.body)
        |> Map.get("lists")
        |> Enum.map(fn seg ->
          %{
            id: seg["id"],
            name: seg["name"]
          }
        end)
        |> IO.inspect()
    end
  end

  defp audiences_url() do
    "#{root_endpoint!()}lists"
  end
end

defmodule FruitPicker.Mailchimp.HTTPClient do
  use HTTPoison.Base

  def process_request_headers(headers) do
    encoded_api_key = Base.encode64(":#{FruitPicker.Mailchimp.api_key!()}")
    [{"Authorization", "Basic #{encoded_api_key}"} | headers]
  end
end
