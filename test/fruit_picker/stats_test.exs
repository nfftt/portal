defmodule FruitPicker.StatsTest do
  use FruitPicker.DataCase

  alias FruitPicker.{Activities, Stats, Repo}
  alias FruitPicker.Activities.Pick

  alias FruitPicker.AccountsFixtures
  alias FruitPicker.ActivitiesFixtures
  alias FruitPicker.PartnersFixtures

  describe "Stats" do
    setup do
      picker =
        AccountsFixtures.person_fixture(%{"number_picks_trigger_waitlist" => 1}, "fruit_picker")

      tree_owner = AccountsFixtures.person_fixture("tree_owner")
      property = AccountsFixtures.property_fixture(tree_owner)

      tree = AccountsFixtures.tree_fixture(property)

      pick_leader =
        AccountsFixtures.person_fixture(
          %{"is_lead_picker" => true},
          "fruit_picker"
        )

      agency = PartnersFixtures.agency_fixture()

      %{
        picker: picker,
        pick_leader: pick_leader,
        tree_owner: tree_owner,
        tree: tree,
        agency: agency
      }
    end

    test "picker stats don't count busts or cancelled picks", %{
      picker: picker,
      pick_leader: pick_leader,
      tree: tree,
      tree_owner: tree_owner,
      agency: agency
    } do
      pick =
        ActivitiesFixtures.scheduled_pick_fixture(
          DateTime.add(DateTime.utc_now(), -1, :day),
          tree_owner,
          tree
        )

      {:ok, pick} = Activities.admin_claim_pick(pick, pick_leader)
      {:ok, pick} = Activities.join_pick(pick, picker)

      {:ok, %{pick_report: pick_report}} =
        Activities.create_report(%{}, pick, pick_leader, [{"#{picker.id}", "true"}])

      {:ok, _} =
        Activities.update_pick_fruits(
          %{
            fruits: [
              %{
                pick_id: pick.id,
                pick_report_id: pick_report.id,
                fruit_category: "apricot",
                fruit_quality: "perfect",
                total_pounds_picked: 5.0,
                # TODO fix this constraint
                total_pounds_donated: 3.0,
                agencies: [%{agency_id: agency.id, pounds_donated: 3.0}]
              }
            ]
          },
          pick.id
        )

      Repo.update!(Pick.complete_changeset(pick))

      canceled_pick = ActivitiesFixtures.scheduled_pick_fixture(tree_owner, tree)
      {:ok, canceled_pick} = Activities.admin_claim_pick(canceled_pick, pick_leader)
      {:ok, canceled_pick} = Activities.join_pick(canceled_pick, picker)

      {:ok, %{pick_report: pick_report}} =
        Activities.create_report(%{}, canceled_pick, pick_leader, [{"#{picker.id}", "true"}])

      {:ok, _canceled_pick} =
        Activities.cancel_pick(canceled_pick, %{reason_for_cancellation: "bad weather"})

      bust =
        ActivitiesFixtures.scheduled_pick_fixture(
          DateTime.add(DateTime.utc_now(), -1, :day),
          tree_owner,
          tree
        )

      {:ok, bust} = Activities.admin_claim_pick(bust, pick_leader)
      {:ok, bust} = Activities.join_pick(bust, picker)

      {:ok, %{pick_report: pick_report}} =
        Activities.create_report(%{}, bust, pick_leader, [{"#{picker.id}", "true"}])

      {:ok, _} =
        Activities.update_pick_fruits(
          %{
            fruits: [
              %{
                pick_id: bust.id,
                pick_report_id: pick_report.id,
                fruit_category: "apricot",
                fruit_quality: "perfect",
                total_pounds_picked: 0.0,
                # TODO fix this constraint
                total_pounds_donated: 0.1,
                agencies: [%{agency_id: agency.id, pounds_donated: 0.1}]
              }
            ]
          },
          bust.id
        )

      Repo.update!(Pick.complete_changeset(bust))

      assert Stats.picker_season_stats(picker) == %{
               "picks" => 1,
               "pounds_donated" => 3.0,
               "pounds_picked" => 5.0
             }

      assert Stats.picker_total_stats(picker) == %{
               "picks" => 1,
               "pounds_donated" => 3.0,
               "pounds_picked" => 5.0
             }

      assert Stats.lead_picker_season_stats(pick_leader) == %{
               "picks_attended" => 0,
               "picks_lead" => 1,
               "pounds_donated" => 3.0,
               "pounds_picked" => 5.0
             }

      assert Stats.lead_picker_total_stats(pick_leader) == %{
               "picks_attended" => 0,
               "picks_lead" => 1,
               "pounds_donated" => 3.0,
               "pounds_picked" => 5.0
             }
    end
  end
end
