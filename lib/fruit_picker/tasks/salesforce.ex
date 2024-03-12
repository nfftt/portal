defmodule FruitPicker.Tasks.Salesforce do
  @moduledoc """
  Scheduled job for syncing contact info with Salesforce.

  Salesforce Field Names:

  Id
  IsDeleted
  MasterRecordId
  AccountId
  Salutation
  FirstName
  LastName
  MiddleName
  Suffix
  OtherStreet
  OtherCity
  OtherState
  OtherPostalCode
  OtherCountry
  OtherLatitude
  OtherLongitude
  OtherGeocodeAccuracy
  MailingStreet
  MailingCity
  MailingState
  MailingPostalCode
  MailingCountry
  MailingLatitude
  MailingLongitude
  MailingGeocodeAccuracy
  Phone
  Fax
  MobilePhone
  HomePhone
  OtherPhone
  AssistantPhone
  ReportsToId
  Email
  Title
  Department
  AssistantName
  LeadSource
  Birthdate
  Description
  OwnerId
  HasOptedOutOfEmail
  HasOptedOutOfFax
  DoNotCall
  CreatedDate
  CreatedById
  LastModifiedDate
  LastModifiedById
  SystemModstamp
  LastActivityDate
  LastCURequestDate
  LastCUUpdateDate
  EmailBouncedReason
  EmailBouncedDate
  Jigsaw
  JigsawContactId
  IndividualId
  npe01__AlternateEmail__c
  npe01__HomeEmail__c
  npe01__PreferredPhone__c
  npe01__Preferred_Email__c
  npe01__Primary_Address_Type__c
  npe01__Private__c
  npe01__Secondary_Address_Type__c
  npe01__SystemAccountProcessor__c
  npe01__WorkEmail__c
  npe01__WorkPhone__c
  npo02__AverageAmount__c
  npo02__Best_Gift_Year_Total__c
  npo02__Best_Gift_Year__c
  npo02__FirstCloseDate__c
  npo02__Household_Naming_Order__c
  npo02__Household__c
  npo02__LargestAmount__c
  npo02__LastCloseDate__c
  npo02__LastMembershipAmount__c
  npo02__LastMembershipDate__c
  npo02__LastMembershipLevel__c
  npo02__LastMembershipOrigin__c
  npo02__LastOppAmount__c
  npo02__MembershipEndDate__c
  npo02__MembershipJoinDate__c
  npo02__Naming_Exclusions__c
  npo02__NumberOfClosedOpps__c
  npo02__NumberOfMembershipOpps__c
  npo02__OppAmount2YearsAgo__c
  npo02__OppAmountLastNDays__c
  npo02__OppAmountLastYear__c
  npo02__OppAmountThisYear__c
  npo02__OppsClosed2YearsAgo__c
  npo02__OppsClosedLastNDays__c
  npo02__OppsClosedLastYear__c
  npo02__OppsClosedThisYear__c
  npo02__SmallestAmount__c
  npo02__Soft_Credit_Last_Year__c
  npo02__Soft_Credit_This_Year__c
  npo02__Soft_Credit_Total__c
  npo02__Soft_Credit_Two_Years_Ago__c
  npo02__SystemHouseholdProcessor__c
  npo02__TotalMembershipOppAmount__c
  npo02__TotalOppAmount__c
  npsp__Batch__c
  npsp__Current_Address__c
  npsp__Deceased__c
  npsp__Do_Not_Contact__c
  npsp__Exclude_from_Household_Formal_Greeting__c
  npsp__Exclude_from_Household_Informal_Greeting__c
  npsp__Exclude_from_Household_Name__c
  npsp__First_Soft_Credit_Amount__c
  npsp__First_Soft_Credit_Date__c
  npsp__Largest_Soft_Credit_Amount__c
  npsp__Largest_Soft_Credit_Date__c
  npsp__Last_Soft_Credit_Amount__c
  npsp__Last_Soft_Credit_Date__c
  npsp__Number_of_Soft_Credits_Last_N_Days__c
  npsp__Number_of_Soft_Credits_Last_Year__c
  npsp__Number_of_Soft_Credits_This_Year__c
  npsp__Number_of_Soft_Credits_Two_Years_Ago__c
  npsp__Number_of_Soft_Credits__c
  npsp__Primary_Affiliation__c
  npsp__Soft_Credit_Last_N_Days__c
  npsp__is_Address_Override__c
  Contact_Type__c
  Snail_Mail_Opt_Out__c
  Volunteer_Active__c
  Volunteer_Registration_Date__c
  Equipment_Set__c
  Volunteer_Roles__c
  Volunteer_Skills__c
  MC4SF__MC_Subscriber__c
  EventbriteSync__EventbriteId__c
  EventbriteSync__EventbriteType__c
  Affinity__c
  Newsletter_Opt_In__c
  Has_a_Car_Can_Provide_Transport__c
  Supreme_Gleaner_Motivation__c
  Yearly_Pick_Commitment__c
  City_Cider_Roles__c
  Contact_Source__c
  Lapsed_Donor__c
  Active_Monthly_Donor__c
  Temporary_Password__c
  """

  @shortdoc "Update Salesforce contact info"

  import Logger

  alias FruitPicker.Repo
  alias FruitPicker.Accounts.{
    Person,
    Property,
    Tree
  }

  @zapier_webhook_url "https://hooks.zapier.com/hooks/catch/3139/ob9smhj/"

  def update_all_people() do
    Person
    |> Repo.all()
    |> Person.preload_profile()
    |> Person.preload_property()
    |> Repo.preload([property: :trees, property: [trees: :snapshots]])
    |> Enum.each(fn person ->
      if person.is_tree_owner do
        person
        |> prepare_contact_info()
        |> prepare_tree_owner_info(person)
        |> send_webhook()
      else
        person
        |> prepare_contact_info()
        |> send_webhook()
      end
    end)
  end

  def update_person(id) do
    person = Person
    |> Repo.get(id)
    |> Person.preload_profile()
    |> Person.preload_property()
    |> Repo.preload([property: :trees, property: [trees: :snapshots]])

    if person.is_tree_owner do
      person
      |> prepare_contact_info()
      |> prepare_tree_owner_info(person)
      |> send_webhook()
    else
      person
      |> prepare_contact_info()
      |> send_webhook()
    end
  end

  defp prepare_contact_info(%Person{} = person) do
    %{
      email: person.email,
      first_name: person.first_name,
      last_name: person.last_name,
      roles: roles(person),
      active_membership: person.membership_is_active,
      phone: person.profile.phone_number,
      phone_secondary: person.profile.secondary_phone_number,
      address_street: person.profile.address_street,
      address_city: person.profile.address_city,
      address_province: Atom.to_string(person.profile.address_province),
      address_postal_code: person.profile.address_postal_code,
      address_country: person.profile.address_country,
      created_date: person.inserted_at,
    }
  end

  defp send_webhook(contact_info) do
    body = Jason.encode!(contact_info)
    Logger.info("Sending Salesforce webhook to Zapier for #{contact_info.email}")

    case HTTPoison.post(@zapier_webhook_url, body) do
      {:ok, response} ->
        if response.status_code == 200 do
          Logger.info("Updated contact info for #{contact_info.email}")
        else
          reason = "wrong response (#{response.status_code})"
          raise(reason)
        end
      {:error, %HTTPoison.Error{:reason => reason}} ->
        raise(reason)
    end
  end

  defp prepare_tree_owner_info(contact_info, %Person{} = person) do
    contact_info
    |> Map.merge(tree_summary(person.property))
    |> Map.put(:property, property_payload(person.property))
    |> Map.put(:trees, tree_payload(person.property))
    |> Map.put(:tree_types, tree_types(person.property))
  end

  defp property_payload(property) do
    if property do
      %{
        my_role: property.my_role,
        address_street: property.address_street,
        address_closest_intersection: property.address_closest_intersection,
        address_city: property.address_city,
        address_postal_code: property.address_postal_code,
        address_province: property.address_province,
        address_country: property.address_country,
        latitude: property.latitude,
        longitude: property.longitude,
        notes: property.notes,
        is_in_operating_area: property.is_in_operating_area,
      }
    else
      %{}
    end
  end

  defp tree_payload(property) do
    if property && property.trees do
      Enum.map(property.trees, fn tree ->
        %{
          id: tree.id,
          nickname: tree.nickname,
          is_active: tree.is_active,
          pickable_this_year: tree.pickable_this_year,
          unpickable_reason: tree.unpickable_reason,
          type: tree.type,
          fruit_variety: tree.fruit_variety,
          height: tree.height,
          earliest_ripening_date: tree.earliest_ripening_date,
          year_planted: tree.year_planted,
          tree_pruned_frequency: tree.tree_pruned_frequency,
          is_tree_sprayed_or_treated: tree.is_tree_sprayed_or_treated,
          deactivate_reason: tree.deactivate_reason,
          receives: tree_receives(tree),
          structural: tree_has(tree),
          pests: tree_pests(tree),
        }
      end)
    else
      []
    end
  end

  defp roles(%Person{} = person) do
    case person.role do
      :admin ->
        "Admin"
      :user ->
        if Enum.any?(friendly_permissions(person)) do
          Enum.map_join(friendly_permissions(person), ", ", &(&1[:name]))
        else
          "Volunteer"
        end
      :agency ->
        "Agency"
    end
  end

  defp friendly_permissions(%Person{} = person) do
    Enum.filter(permissions_list(person), fn person -> person.check == true end)
  end

  defp permissions_list(%Person{} = person) do
    [
      %{
        name: "Fruit Picker",
        check: person.is_picker
      },
      %{
        name: "Lead Picker",
        check: person.is_lead_picker
      },
      %{
        name: "Tree Owner",
        check: person.is_tree_owner
      }
    ]
  end

  defp friendly_truthy(value) do
    if value, do: "Yes", else: "No"
  end

  defp tree_receives(%Tree{} = tree) do
    if Enum.any?(tree.snapshots) do
      items = tree.snapshots
      |> Enum.sort_by(&Map.fetch!(&1, :inserted_at), &>=/2)
      |> Enum.at(0)

      Enum.filter(tree_receives_list(items), fn tree -> tree.receives == true end)
    else
      Enum.filter(tree_receives_list(tree), fn tree -> tree.receives == true end)
    end
  end

  defp tree_receives_list(tree) do
    [
      %{
        name: "Mulching",
        receives: tree.receive_mulching,
      },
      %{
        name: "Watering",
        receives: tree.receive_watering,
      },
      %{
        name: "Pruning",
        receives: tree.receive_pruning,
      },
      %{
        name: tree.receive_other,
        receives: (if tree.receive_other == "", do: true, else: false)
      }
    ]
  end

  defp tree_has(%Tree{} = tree) do
    if Enum.any?(tree.snapshots) do
      items = tree.snapshots
      |> Enum.sort_by(&Map.fetch!(&1, :inserted_at), &>=/2)
      |> Enum.at(0)

      Enum.filter(tree_has_list(items), fn tree -> tree.has == true end)
    else
      Enum.filter(tree_has_list(tree), fn tree -> tree.has == true end)
    end
  end

  defp tree_has_list(tree) do
    [
      %{
        name: "Broken or hanging branches",
        has: tree.has_broken_branches,
      },
      %{
        name: "Limbs with missing bark",
        has: tree.has_limbs_missing_bark,
      },
      %{
        name: "Bare branches with no new leaf or bud growth",
        has: tree.has_bare_branches_no_growth,
      },
      %{
        name: "Cavities or rotten wood along the trunk or in major branches",
        has: tree.has_rotten_wood,
      },
      %{
        name: "Deep, large cracks in the trunk",
        has: tree.has_large_trunk_cracks,
      },
      %{
        name: "Mushrooms present at base of tree",
        has: tree.has_mushrooms_at_base,
      },
      %{
        name: "Trunk as a strong lean",
        has: tree.has_trunk_strong_lean,
      },
      %{
        name: "Has no issues",
        has: tree.has_no_issues,
      }
    ]
  end

  defp tree_pests(%Tree{} = tree) do
    if Enum.any?(tree.snapshots) do
      items = tree.snapshots
      |> Enum.sort_by(&Map.fetch!(&1, :inserted_at), &>=/2)
      |> Enum.at(0)

      Enum.filter(tree_pests_list(items), fn tree -> tree.pest == true end)
    else
      Enum.filter(tree_pests_list(tree), fn tree -> tree.pest == true end)
    end
  end

  defp tree_pests_list(tree) do
    [
      %{
        name: "Pests on the tree (beetles, ants, aphids, mites, etc.)",
        pest: tree.pests_on_tree,
      },
      %{
        name: "Yellow of orange coloured spots on the leaves",
        pest: tree.pests_yellow_spots_on_leaves,
      },
      %{
        name: "Twigs or branches are swollen, black, and twisted",
        pest: tree.pests_swollen_twisted_branches,
      },
      %{
        name: "Tree leaves covered in small dark coloured spots, which turn into holes",
        pest: tree.pests_leaves_small_dark_spots_holes,
      },
      %{
        name: "Dark, brown spots on fruit that harden into scabs",
        pest: tree.pests_brown_spots_fruit_scabs,
      },
      %{
        name: "Fruit and leaves appear to be rotting or decomposing on branches",
        pest: tree.pests_rotting_fruit_on_branches,
      },
      %{
        name: "Powdery mildew on fruit or leaves",
        pest: tree.pests_powdery_mildew,
      },
      %{
        name: "Leaves are dried out, and have turned black or brown; withering fruit",
        pest: tree.pests_dried_out_leaves_withering_fruit,
      },
      %{
        name: "Branches or bark are oozing amber-coloured sappy liquid",
        pest: tree.pests_oozing_sappy_liquid,
      },
      %{
        name: "No evidence of pests or disease",
        pest: tree.pests_none,
      }
    ]
  end

  defp tree_types(property) do
    if property && property.trees do
      property.trees
      |> Enum.map(fn tree -> tree.type end)
      |> Enum.sort()
      |> Enum.chunk_by(fn type -> type end)
      |> Enum.map(fn tree_type_list -> (if length(tree_type_list) > 1 do "#{hd(tree_type_list)} x#{length(tree_type_list)}" else hd(tree_type_list) end) end)
      |> Enum.join(", ")
    else
      nil
    end
  end

  defp tree_summary(property) do
    if property && property.trees do
      property.trees
      |> Enum.sort()
      |> Enum.chunk_by(fn tree -> tree.type end)
      |> Enum.map(fn tree_type ->
        tree = List.first(tree_type)

        %{}
        |> Map.put(tree.type <> " Trees", length(tree_type))
        |> Map.put(tree.type <> " Tree Height", tree.height)
        |> Map.put(tree.type <> " Tree Status", (if tree.unpickable_reason, do: tree.unpickable_reason, else: "Active"))
      end)
      |> Enum.concat()
      |> Enum.into(%{})
    else
      %{}
    end
  end
end
