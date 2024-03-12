defmodule FruitPickerWeb.DashboardController do
  use FruitPickerWeb, :controller

  alias FruitPicker.Accounts.Person
  alias FruitPicker.Activities
  alias FruitPicker.Activities.Pick
  alias FruitPicker.Partners
  alias FruitPickerWeb.Policies

  def index(conn, params) do
    person = conn.assigns.current_person
    dashboard_type = get_dashboard_type(person)

    case dashboard_type do
      :admin ->
        admin_dashboard(conn)

      :volunteer ->
        cond do
          person.is_lead_picker ->
            case has_outstanding_pick(person) do
              %Pick{} = pick ->
                locked_out_dashboard(conn, pick)

              nil ->
                volunteer_dashboard(conn, params)
            end

          person.membership_is_active ->
            volunteer_dashboard(conn, params)

          true ->
            render(conn, "inactive.html")
        end

      :agency ->
        agency_dashboard(conn)

      _ ->
        render(conn, "index.html")
    end
  end

  defp volunteer_dashboard(conn, params) do
    Policies.enforce(conn, :tree_owner_has_requested_pick)

    acp_sort_by = Map.get(params, "acp_sort_by")
    acp_desc = Map.get(params, "acp_desc")
    ajp_sort_by = Map.get(params, "ajp_sort_by")
    ajp_desc = Map.get(params, "ajp_desc")
    mlcp_sort_by = Map.get(params, "mlcp_sort_by")
    mlcp_desc = Map.get(params, "mlcp_desc")
    msp_sort_by = Map.get(params, "msp_sort_by")
    msp_desc = Map.get(params, "msp_desc")

    me = conn.assigns.current_person

    tree_requested_picks = Activities.list_my_picks_by_status(me, :submitted, :scheduled)
    tree_incomplete_picks = Activities.list_my_picks_by_status(me, :started)
    tree_scheduled_picks = Activities.list_my_picks_by_status(me, :claimed)
    tree_rescheduled_picks = Activities.list_my_picks_by_status(me, :rescheduled, :canceled)
    tree_completed_picks = Activities.summary_my_tree_completed_picks(me)

    available_to_claim_picks =
      Activities.summary_available_picks_to_claim(me, acp_sort_by, acp_desc)

    available_to_join_picks =
      Activities.summary_available_picks_to_join(me, ajp_sort_by, ajp_desc)

    my_scheduled_lead_picks =
      Activities.summary_my_scheduled_lead_picks(me, msp_sort_by, msp_desc)

    my_scheduled_picks = Activities.summary_my_scheduled_picks(me, msp_sort_by, msp_desc)

    my_lead_completed_picks =
      Activities.summary_my_lead_completed_picks(me, mlcp_sort_by, mlcp_desc)

    picks_this_week = Activities.count_this_week()

    %{
      "pounds_picked" => pounds_picked_this_season,
      "pounds_donated" => pounds_donated_this_season
    } = Activities.count_pounds_this_season()

    render(conn, "volunteer.html",
      acp_sort_by: acp_sort_by,
      acp_desc: acp_desc,
      mlcp_sort_by: mlcp_sort_by,
      mlcp_desc: mlcp_desc,
      ajp_sort_by: ajp_sort_by,
      ajp_desc: ajp_desc,
      msp_sort_by: msp_sort_by,
      msp_desc: msp_desc,
      tree_requested_picks: tree_requested_picks,
      tree_incomplete_picks: tree_incomplete_picks,
      tree_scheduled_picks: tree_scheduled_picks,
      tree_rescheduled_picks: tree_rescheduled_picks,
      tree_completed_picks: tree_completed_picks,
      available_to_join_picks: available_to_join_picks,
      available_to_claim_picks: available_to_claim_picks,
      # TODO: properly sort the below pick list or combine into one query
      my_scheduled_picks: my_scheduled_lead_picks ++ my_scheduled_picks,
      my_lead_completed_picks: my_lead_completed_picks,
      picks_this_week: picks_this_week,
      pounds_picked_this_season: pounds_picked_this_season,
      pounds_donated_this_season: pounds_donated_this_season
    )
  end

  defp agency_dashboard(conn) do
    agency = Partners.get_my_agency!(conn.assigns.current_person)
    scheduled_picks = Partners.get_scheduled_picks(agency)
    completed_picks = Partners.get_completed_picks(agency)

    render(conn, "index.html",
      completed_picks: completed_picks,
      scheduled_picks: scheduled_picks
    )
  end

  defp admin_dashboard(conn) do
    pick_request_count = Activities.pick_request_count()
    requested_picks = Activities.summary_picks_by_status(:submitted, :rescheduled)
    claimed_picks = Activities.summary_picks_by_status(:claimed)
    unclaimed_picks = Activities.summary_picks_by_status(:scheduled)
    picks_this_week = Activities.count_this_week()
    picks_this_season = Activities.count_this_season()

    %{
      "pounds_picked" => pounds_picked_this_season,
      "pounds_donated" => pounds_donated_this_season
    } = Activities.count_pounds_this_season()

    render(conn, "admin.html",
      pick_request_count: pick_request_count,
      requested_picks: requested_picks,
      claimed_picks: claimed_picks,
      unclaimed_picks: unclaimed_picks,
      picks_this_week: picks_this_week,
      picks_this_season: picks_this_season,
      pounds_picked_this_season: pounds_picked_this_season,
      pounds_donated_this_season: pounds_donated_this_season
    )
  end

  defp locked_out_dashboard(conn, pick) do
    render(conn, "locked_out.html", pick: pick)
  end

  defp get_dashboard_type(%Person{} = person) do
    cond do
      person.role == :admin ->
        :admin

      person.role == :agency ->
        :agency

      person.role == :user ->
        :volunteer

      true ->
        :user
    end
  end

  defp has_outstanding_pick(%Person{} = person) do
    person
    |> Activities.picks_with_outstanding_report()
    |> Enum.at(0)
  end
end
