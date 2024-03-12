defmodule FruitPicker.ActivitiesTest do
  use FruitPicker.DataCase

  alias FruitPicker.Activities

  alias FruitPicker.AccountsFixtures
  alias FruitPicker.ActivitiesFixtures
  alias FruitPicker.PartnersFixtures

  describe "Throttling" do
    setup do
      person =
        AccountsFixtures.person_fixture(%{"number_picks_trigger_waitlist" => 1}, "fruit_picker")

      tree_owner = AccountsFixtures.person_fixture("tree_owner")
      property = AccountsFixtures.property_fixture(tree_owner)

      tree = AccountsFixtures.tree_fixture(property)

      pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)

      pick_leader =
        AccountsFixtures.person_fixture(
          %{"is_lead_picker" => true},
          "fruit_picker"
        )

      agency = PartnersFixtures.agency_fixture()

      %{
        person: person,
        pick_leader: pick_leader,
        pick: pick,
        tree_owner: tree_owner,
        tree: tree,
        agency: agency
      }
    end

    test "person_has_more_picks_than_waitlist_threshold", %{person: person, pick: pick} do
      refute Activities.person_has_more_picks_than_waitlist_threshold(person)
      Activities.join_pick(pick, person)
      assert Activities.person_has_more_picks_than_waitlist_threshold(person)
    end

    test "pickers can't sign up for more than 5 picks", %{tree: tree, tree_owner: tree_owner} do
      person = AccountsFixtures.person_fixture("fruit_picker")

      for _ <- 0..4 do
        pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
        refute Activities.requires_wait(pick, person)
        {:ok, _pick} = Activities.join_pick(pick, person)
      end

      pick6 = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
      assert Activities.requires_wait(pick6, person)
    end

    test "picker can sign up for more than 5 picks if it's less than 5 hours from now", %{
      tree: tree,
      tree_owner: tree_owner
    } do
      person = AccountsFixtures.person_fixture("fruit_picker")

      for _ <- 0..4 do
        pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
        refute Activities.requires_wait(pick, person)
        {:ok, _pick} = Activities.join_pick(pick, person)
      end

      pick6 =
        ActivitiesFixtures.scheduled_pick_fixture(
          DateTime.utc_now(),
          tree_owner,
          tree
        )

      refute Activities.requires_wait(pick6, person)
    end

    test "busts are not counted", %{
      pick_leader: pick_leader,
      tree: tree,
      tree_owner: tree_owner,
      agency: agency
    } do
      picker = AccountsFixtures.person_fixture("fruit_picker")

      # Go on four picks
      for _ <- 0..3 do
        pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
        refute Activities.requires_wait(pick, picker)
        {:ok, _pick} = Activities.join_pick(pick, picker)
      end

      # Go on a bust (busts are only counted in the past)
      bust =
        ActivitiesFixtures.scheduled_pick_fixture(
          DateTime.add(DateTime.utc_now(), -1, :day),
          tree_owner,
          tree
        )

      {:ok, bust} = Activities.admin_claim_pick(bust, pick_leader)
      {:ok, bust} = Activities.join_pick(bust, picker)
      {:ok, %{pick_report: pick_report}} = Activities.create_report(%{}, bust, pick_leader, [])

      {:ok, _} =
        Activities.update_pick_fruits(
          %{
            fruits: [
              %{
                pick_id: bust.id,
                pick_report_id: pick_report.id,
                fruit_category: "apricot",
                fruit_quality: "perfect",
                total_pounds_picked: 4.0,
                # TODO fix this constraint
                total_pounds_donated: 3.0,
                agencies: [%{agency_id: agency.id, pounds_donated: 3.0}]
              }
            ]
          },
          bust.id
        )

      # Can still go on a 6th pick
      pick6 = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
      refute Activities.requires_wait(pick6, picker)
    end

    test "canceled picks are not counted", %{
      tree: tree,
      tree_owner: tree_owner
    } do
      picker = AccountsFixtures.person_fixture("fruit_picker")

      # Go on four picks
      for _ <- 0..3 do
        pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
        refute Activities.requires_wait(pick, picker)
        {:ok, _pick} = Activities.join_pick(pick, picker)
      end

      # Go on a canceled pick
      canceled_pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
      refute Activities.requires_wait(canceled_pick, picker)
      {:ok, canceled_pick} = Activities.join_pick(canceled_pick, picker)

      {:ok, _canceled_pick} =
        Activities.cancel_pick(canceled_pick, %{reason_for_cancellation: "bad weather"})

      # Can still go on a 6th pick
      pick6 = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
      refute Activities.requires_wait(pick6, picker)
    end

    test "A pick you're already signed up for as picker doesn't require wait", %{
      tree: tree,
      tree_owner: tree_owner
    } do
      person = AccountsFixtures.person_fixture("fruit_picker")

      # Sign up for 4 picks
      for _ <- 0..3 do
        pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
        refute Activities.requires_wait(pick, person)
        {:ok, _pick} = Activities.join_pick(pick, person)
      end

      pick5 = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
      refute Activities.requires_wait(pick5, person)
      {:ok, pick5} = Activities.join_pick(pick5, person)

      pick6 = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
      assert Activities.requires_wait(pick6, person)

      refute Activities.requires_wait(pick5, person)
    end

    test "pick leaders can sign up to lead as many picks as they want", %{
      pick_leader: pick_leader,
      tree_owner: tree_owner,
      tree: tree
    } do
      # sign up for 5 picks as pick leader
      for _ <- 0..4 do
        pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
        {:ok, _pick} = Activities.admin_claim_pick(pick, pick_leader)
      end

      # can sign up to the 6th pick as a picker
      pick6 =
        ActivitiesFixtures.scheduled_pick_fixture(
          tree_owner,
          tree
        )

      refute Activities.requires_wait(pick6, pick_leader)
    end

    test "pick leaders can't sign up for more than 5 picks", %{
      pick_leader: pick_leader,
      tree_owner: tree_owner,
      tree: tree
    } do
      # go on 5 picks as a picker
      for _ <- 0..4 do
        pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
        refute Activities.requires_wait(pick, pick_leader)
        {:ok, _pick} = Activities.join_pick(pick, pick_leader)
      end

      # can't sign up to a 6th pick
      pick6 = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
      assert Activities.requires_wait(pick6, pick_leader)
    end

    test "pick leaders can lead picks after they've exhausted their picks as pickers", %{
      pick_leader: pick_leader,
      tree_owner: tree_owner,
      tree: tree
    } do
      # sign up for 5 picks as picker
      for _ <- 0..4 do
        pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
        refute Activities.requires_wait(pick, pick_leader)
        {:ok, _pick} = Activities.join_pick(pick, pick_leader)
      end

      # can sign up to the 6th pick as a pick leader
      pick6 = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
      {:ok, pick6} = Activities.admin_claim_pick(pick6, pick_leader)
      refute Activities.requires_wait(pick6, pick_leader)
    end

    test "staff can sign up for more than 5 picks", %{tree_owner: tree_owner, tree: tree} do
      staff = AccountsFixtures.person_fixture("admin")

      for _ <- 0..4 do
        pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
        refute Activities.requires_wait(pick, staff)
        {:ok, _pick} = Activities.join_pick(pick, staff)
      end

      pick6 = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
      refute Activities.requires_wait(pick6, staff)
    end

    test "picks with two reports are only counted once", %{
      tree: tree,
      tree_owner: tree_owner,
      pick_leader: pick_leader,
      person: person,
      agency: agency
    } do
      # There's a UI bug where some picks have multiple reports. We have to account for it by only counting them once
      pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
      {:ok, pick} = Activities.admin_claim_pick(pick, pick_leader)
      {:ok, pick} = Activities.join_pick(pick, person)
      {:ok, %{pick_report: pick_report}} = Activities.create_report(%{}, pick, pick_leader, [])

      {:ok, _} =
        Activities.update_pick_fruits(
          %{
            fruits: [
              %{
                pick_id: pick.id,
                pick_report_id: pick_report.id,
                fruit_category: "apricot",
                fruit_quality: "perfect",
                total_pounds_picked: 20.0,
                # TODO fix this constraint
                total_pounds_donated: 20.0,
                agencies: [%{agency_id: agency.id, pounds_donated: 20.0}]
              }
            ]
          },
          pick.id
        )

      {:ok, %{pick_report: _pick_report2}} = Activities.create_report(%{}, pick, pick_leader, [])

      assert Activities.count_picks_for_person_this_season(person) == 1
    end

    test "completed picks with no report are considered busts", %{
      tree: tree,
      tree_owner: tree_owner,
      person: person,
    } do
      past_pick =
        ActivitiesFixtures.scheduled_pick_fixture(
          DateTime.add(DateTime.utc_now(), -1, :day),
          tree_owner,
          tree
        )

      {:ok, _past_pick} = Activities.join_pick(past_pick, person)

      future_pick =
        ActivitiesFixtures.scheduled_pick_fixture(
          DateTime.add(DateTime.utc_now(), 2, :hour),
          tree_owner,
          tree
        )

      {:ok, _future_pick} = Activities.join_pick(future_pick, person)

      assert Activities.count_picks_for_person_this_season(person) == 1
    end
  end

  describe "Pick Reports" do
    setup do
      person =
        AccountsFixtures.person_fixture(%{"number_picks_trigger_waitlist" => 1}, "fruit_picker")

      tree_owner = AccountsFixtures.person_fixture("tree_owner")
      property = AccountsFixtures.property_fixture(tree_owner)

      tree = AccountsFixtures.tree_fixture(property)

      pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)

      pick_leader =
        AccountsFixtures.person_fixture(
          %{"is_lead_picker" => true},
          "fruit_picker"
        )

      agency = PartnersFixtures.agency_fixture()

      %{
        person: person,
        pick_leader: pick_leader,
        pick: pick,
        tree_owner: tree_owner,
        tree: tree,
        agency: agency
      }
    end

    test "`picks_with_outstanding_report/0` and `picks_with_outstanding_report/1` doesn't double count picks with multiple reports",
         %{
           pick_leader: pick_leader,
           tree: tree,
           tree_owner: tree_owner,
         } do
      yesterday = DateTime.add(DateTime.utc_now(), -1, :day)

      pick = ActivitiesFixtures.scheduled_pick_fixture(yesterday, tree_owner, tree)

      {:ok, _pick} = Activities.admin_claim_pick(pick, pick_leader)
      # Mark the pick complete
      FruitPicker.Tasks.Picks.Complete.complete_picks()

      # Make a report
      {:ok, %{pick_report: pick_report}} = Activities.create_report(%{}, pick, pick_leader, [])

      # Make a second report
      {:ok, %{pick_report: pick_report2}} = Activities.create_report(%{}, pick, pick_leader, [])

      # Make a third report
      {:ok, %{pick_report: _pick_report3}} = Activities.create_report(%{}, pick, pick_leader, [])

      # One pick has an outstanding report
      assert Activities.picks_with_outstanding_report() |> Enum.count() == 1
      assert Activities.picks_with_outstanding_report(pick_leader) |> Enum.count() == 1

      # Completing the first and second reports should make it so no picks have outstanding reports
      {:ok, _} = Activities.complete_report(pick_report)

      assert Activities.picks_with_outstanding_report() |> Enum.count() == 0
      assert Activities.picks_with_outstanding_report(pick_leader) |> Enum.count() == 0

      {:ok, _} = Activities.complete_report(pick_report2)

      assert Activities.picks_with_outstanding_report() |> Enum.count() == 0
      assert Activities.picks_with_outstanding_report(pick_leader) |> Enum.count() == 0
    end

    test "get_pick_report_by_pick_id/1", %{
      pick_leader: pick_leader,
      tree: tree,
      tree_owner: tree_owner,
    } do
      yesterday = DateTime.add(DateTime.utc_now(), -1, :day)

      pick = ActivitiesFixtures.scheduled_pick_fixture(yesterday, tree_owner, tree)

      {:ok, _pick} = Activities.admin_claim_pick(pick, pick_leader)
      # Mark the pick complete
      FruitPicker.Tasks.Picks.Complete.complete_picks()

      # Make a report
      {:ok, %{pick_report: pick_report}} = Activities.create_report(%{}, pick, pick_leader, [])

      pr = Activities.get_pick_report_by_pick_id(pick.id)

      assert pr.pick_id == pick.id
      assert pr.id == pick_report.id

      # Make a second report
      {:ok, %{pick_report: _pick_report2}} = Activities.create_report(%{}, pick, pick_leader, [])

      pr = Activities.get_pick_report_by_pick_id(pick.id)
      assert pr.pick_id == pick.id

      # Make sure we get first pick report
      assert pr.id == pick_report.id
    end
  end
end
