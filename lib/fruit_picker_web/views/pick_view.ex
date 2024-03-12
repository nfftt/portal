defmodule FruitPickerWeb.PickView do
  use FruitPickerWeb, :view

  import Scrivener.HTML

  alias FruitPicker.Activities.Pick
  alias FruitPicker.Accounts.{Person, Tree}
  alias FruitPickerWeb.SharedView
  alias FruitPickerWeb.TreeView

  def show_today() do
    Timex.now("America/Toronto")
    |> Timex.format!("%B %e, %Y", :strftime)
  end

  def friendly_date(date) do
    date
    |> Timex.format!("%B %e, %Y", :strftime)
  end

  def pick_time(%Pick{} = pick) do
    cond do
      pick.pick_time_any ->
        "9:00 AM - 9:00 PM"

      pick.pick_time_morning and pick.pick_time_afternoon and pick.pick_time_evening ->
        "9:00 AM - 9:00 PM"

      pick.pick_time_morning and pick.pick_time_evening ->
        "9:00 AM - 12:00 PM or 5:00 PM - 9:00 PM"

      pick.pick_time_morning and pick.pick_time_afternoon ->
        "9:00 AM - 5:00 PM"

      pick.pick_time_afternoon and pick.pick_time_evening ->
        "12:00 PM - 9:00 PM"

      pick.pick_time_morning ->
        "9:00 AM - 12:00 PM"

      pick.pick_time_afternoon ->
        "12:00 PM - 5:00 PM"

      pick.pick_time_evening ->
        "5:00 PM - 9:00 PM"

      true ->
        "None"
    end
  end

  def tree_has_snapshot?(%Pick{} = pick, %Tree{} = tree) do
    Enum.any?(
      pick.tree_snapshots,
      fn sp ->
        sp.tree_id == tree.id
      end
    )
  end

  def tree_card_class(tree_1, tree_2) do
    if tree_1.id != tree_2.id, do: "o-60"
  end

  def pick_requires_more_snapshots?(%Pick{} = pick) do
    pick_tree_ids = Enum.map(pick.trees, fn t -> t.id end)
    snapshot_tree_ids = Enum.map(pick.tree_snapshots, fn sp -> sp.tree_id end)

    Enum.all?(pick.trees, fn t -> Enum.member?(snapshot_tree_ids, t.id) end)
  end

  def tree_checked?(%Pick{} = pick, tree) do
    Enum.any?(pick.trees, fn t -> t.id == tree.id end)
  end

  def tree_checked?(%Ecto.Changeset{} = changeset, tree) do
    cond do
      changeset.changes[:trees] ->
        Enum.any?(changeset.changes.trees, fn t -> t.id == tree.id end)

      changeset.data.trees ->
        Enum.any?(changeset.data.trees, fn t -> t.id == tree.id end)

      true ->
        false
    end
  end

  def tree_type(%Pick{} = pick) do
    pick.trees
    |> Enum.map(fn tree -> tree.type end)
    |> Enum.sort()
    |> Enum.chunk_by(fn type -> type end)
    |> Enum.map(fn tree_type_list ->
      if length(tree_type_list) > 1 do
        "#{hd(tree_type_list)} x#{length(tree_type_list)}"
      else
        hd(tree_type_list)
      end
    end)
    |> Enum.join(", ")
  end

  def friendly_status(%Pick{} = pick) do
    case pick.status do
      :started ->
        "Incomplete Request"

      :submitted ->
        "Requested by Tree Owner"

      # this means "activated"
      :scheduled ->
        "Unclaimed"

      :claimed ->
        "Scheduled"

      :canceled ->
        "Canceled"

      :rescheduled ->
        "Rescheduled"

      :completed ->
        "Completed"
    end
  end

  def status_class(status) do
    case status do
      :started ->
        "red"

      :submitted ->
        "yellow"

      # this means "activated"
      :scheduled ->
        "red"

      :claimed ->
        "green"

      :canceled ->
        "red"

      :rescheduled ->
        "green"

      :completed ->
        "dark-green"

      _ ->
        "dark-gray"
    end
  end

  def is_submitted?(%Pick{} = pick) do
    pick.status == :submitted
  end

  def is_unclaimed?(%Pick{} = pick) do
    pick.status == :scheduled
  end

  def is_scheduled?(%Pick{} = pick) do
    pick.status == :scheduled
  end

  def is_claimed?(%Pick{} = pick) do
    pick.status == :claimed
  end

  def is_completed?(%Pick{} = pick) do
    pick.status == :completed
  end

  def is_rescheduled?(%Pick{} = pick) do
    pick.status == :rescheduled
  end

  def is_canceled?(%Pick{} = pick) do
    pick.status == :canceled
  end

  def am_lead_picker?(%Pick{} = pick, %Person{} = person) do
    pick.lead_picker_id == person.id
  end

  def lead_picker_and_canceled?(%Pick{} = pick, %Person{} = person) do
    pick.status == :canceled and person.is_lead_picker
  end

  def is_my_requested_pick?(%Pick{} = pick, %Person{} = person) do
    pick.requester_id == person.id
  end

  def show_team?(%Pick{} = pick, %Person{} = person) do
    (pick.status == :canceled and person.is_lead_picker) or
      (Enum.member?([:claimed, :rescheduled, :completed], pick.status) and
         pick.lead_picker_id == person.id) or
      Enum.member?(Enum.map(pick.pickers, fn p -> p.id end), person.id)
  end

  def show_team_class(%Pick{} = pick, %Person{} = person) do
    if show_team?(pick, person) do
      "padding-pick-l"
    end
  end

  def show_map?(%Pick{} = pick, %Person{} = person) do
    Enum.member?([:claimed, :completed], pick.status) &&
      (am_lead_picker?(pick, person) || already_joined_pick?(pick, person))
  end

  def pick_has_spot?(%Pick{} = pick) do
    length(pick.pickers) < (pick.volunteers_max || 5)
  end

  def already_joined_pick?(%Pick{} = pick, %Person{} = picker) do
    Enum.member?(Enum.map(pick.pickers, fn p -> p.id end), picker.id)
  end

  def can_lead_pick?(%Pick{} = pick, %Person{} = lead_picker) do
    lead_picker.is_lead_picker and is_nil(pick.lead_picker_id)
  end

  def pick_status_to_lead?(%Pick{} = pick) do
    pick.status not in [:started, :claimed, :completed, :rescheduled]
  end

  def can_join_pick?(%Pick{} = pick, %Person{} = picker) do
    Enum.member?([:submitted, :scheduled, :claimed, :rescheduled], pick.status) &&
      not is_nil(pick.lead_picker_id) &&
      picker.is_picker and not already_joined_pick?(pick, picker)
  end

  def cancel_options do
    [
      {"I have a scheduling conflict and want to reschedule",
       "I have a scheduling conflict and want to reschedule"},
      {"My fruit has already fallen off the tree", "My fruit has already fallen off the tree"},
      {"My fruit isn't ripe yet, I need to reschedule",
       "My fruit isn't ripe yet, I need to reschedule"},
      {"My fruit has bugs", "My fruit has bugs"},
      {"My fruit is rotten", "My fruit is rotten"}
    ]
  end

  def schedule_pick_available_hours(%Pick{} = pick, :start) do
    cond do
      pick.pick_time_any ->
        morning_hours_start ++ afternoon_hours_start ++ evening_hours_start

      pick.pick_time_morning and pick.pick_time_afternoon and pick.pick_time_evening ->
        morning_hours_start ++ afternoon_hours_start ++ evening_hours_start

      pick.pick_time_morning and pick.pick_time_evening ->
        morning_hours_start ++ evening_hours_start

      pick.pick_time_morning and pick.pick_time_afternoon ->
        morning_hours_start ++ afternoon_hours_start

      pick.pick_time_afternoon and pick.pick_time_evening ->
        afternoon_hours_start ++ evening_hours_start

      pick.pick_time_morning ->
        morning_hours_start

      pick.pick_time_afternoon ->
        afternoon_hours_start

      pick.pick_time_evening ->
        evening_hours_start

      true ->
        []
    end
  end

  def schedule_pick_available_hours(%Pick{} = pick, :end) do
    cond do
      pick.pick_time_any ->
        morning_hours_end ++ afternoon_hours_end ++ evening_hours_end

      pick.pick_time_morning and pick.pick_time_afternoon and pick.pick_time_evening ->
        morning_hours_end ++ afternoon_hours_end ++ evening_hours_end

      pick.pick_time_morning and pick.pick_time_evening ->
        morning_hours_end ++ evening_hours_end

      pick.pick_time_morning and pick.pick_time_afternoon ->
        morning_hours_end ++ afternoon_hours_end

      pick.pick_time_afternoon and pick.pick_time_evening ->
        afternoon_hours_end ++ evening_hours_end

      pick.pick_time_morning ->
        morning_hours_end

      pick.pick_time_afternoon ->
        afternoon_hours_end

      pick.pick_time_evening ->
        evening_hours_end

      true ->
        []
    end
  end

  def is_cancelable?(%Pick{} = pick) do
    Enum.member?([:submitted, :scheduled, :claimed, :rescheduled], pick.status)
  end

  def tree_hover_classes(%Tree{} = tree) do
    if tree.is_active, do: "tree-block-hover pointer"
  end

  def tree_hover_classes(tree) do
    ""
  end

  defp morning_hours_start do
    [
      {"9:00 AM", "09:00:00"},
      {"9:30 AM", "09:30:00"},
      {"10:00 AM", "10:00:00"},
      {"10:30 AM", "10:30:00"},
      {"11:00 AM", "11:00:00"},
      {"11:30 AM", "11:30:00"},
      {"12:00 PM", "12:00:00"}
    ]
  end

  defp morning_hours_end do
    [
      {"9:30 AM", "09:30:00"},
      {"10:00 AM", "10:00:00"},
      {"10:30 AM", "10:30:00"},
      {"11:00 AM", "11:00:00"},
      {"11:30 AM", "11:30:00"},
      {"12:00 PM", "12:00:00"}
    ]
  end

  defp afternoon_hours_start do
    [
      {"12:00 PM", "12:00:00"},
      {"12:30 PM", "12:30:00"},
      {"1:00 PM", "13:00:00"},
      {"1:30 PM", "13:30:00"},
      {"2:00 PM", "14:00:00"},
      {"2:30 PM", "14:30:00"},
      {"3:00 PM", "15:00:00"},
      {"3:30 PM", "15:30:00"},
      {"4:00 PM", "16:00:00"},
      {"4:30 PM", "16:30:00"}
    ]
  end

  defp afternoon_hours_end do
    [
      {"12:00 PM", "12:00:00"},
      {"12:30 PM", "12:30:00"},
      {"1:00 PM", "13:00:00"},
      {"1:30 PM", "13:30:00"},
      {"2:00 PM", "14:00:00"},
      {"2:30 PM", "14:30:00"},
      {"3:00 PM", "15:00:00"},
      {"3:30 PM", "15:30:00"},
      {"4:00 PM", "16:00:00"},
      {"4:30 PM", "16:30:00"}
    ]
  end

  defp evening_hours_start do
    [
      {"5:00 PM", "17:00:00"},
      {"5:30 PM", "17:30:00"},
      {"6:00 PM", "18:00:00"},
      {"6:30 PM", "18:30:00"},
      {"7:00 PM", "19:00:00"}
    ]
  end

  defp evening_hours_end do
    [
      {"5:00 PM", "17:00:00"},
      {"5:30 PM", "17:30:00"},
      {"6:00 PM", "18:00:00"},
      {"6:30 PM", "18:30:00"},
      {"7:00 PM", "19:00:00"},
      {"7:30 PM", "19:30:00"},
      {"8:00 PM", "20:00:00"},
      {"8:30 PM", "20:30:00"},
      {"9:00 PM", "21:00:00"}
    ]
  end

  def get_attendee(pickers, id) do
    Enum.find(pickers, fn p -> p.id == id end)
  end

  def show_pick_report?(pick, person) do
    am_lead_picker?(pick, person) and
      not is_nil(pick.report) and
      pick.lead_picker.id == pick.report.submitter.id and
      pick.report.is_complete
  end
end
