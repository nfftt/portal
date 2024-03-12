defmodule FruitPickerWeb.Admin.PickView do
  use FruitPickerWeb, :view

  import Scrivener.HTML
  import FruitPickerWeb.PickView, only: [pick_time: 1]

  alias FruitPicker.Activities.Pick
  alias FruitPicker.Accounts.{Person, Tree}
  alias FruitPickerWeb.Admin.PersonView
  alias FruitPickerWeb.SharedView

  def show_today() do
    Timex.now("America/Toronto")
    |> Timex.format!("%B %e, %Y", :strftime)
  end

  def friendly_date(date) do
    date
    |> Timex.format!("%B %e, %Y", :strftime)
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

  def friendly_status(status) do
    cond do
      status == :scheduled ->
        "unclaimed"

      status == :started ->
        "incomplete"

      true ->
        Atom.to_string(status)
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
        :completed
        "dark-green"

      _ ->
        "dark-gray"
    end
  end

  def is_started?(%Pick{} = pick) do
    pick.status == :started
  end

  def is_submitted?(%Pick{} = pick) do
    pick.status == :submitted
  end

  def is_unclaimed?(%Pick{} = pick) do
    pick.status == :scheduled
  end

  def is_claimed?(%Pick{} = pick) do
    pick.status == :claimed
  end

  def is_rescheduled?(%Pick{} = pick) do
    pick.status == :rescheduled
  end

  def is_canceled?(%Pick{} = pick) do
    pick.status == :canceled
  end

  def is_completed?(%Pick{} = pick) do
    pick.status == :completed
  end

  def show_map?(%Pick{} = pick) do
    Enum.member?([:claimed, :completed], pick.status)
  end

  def show_team?(%Pick{} = pick) do
    Enum.member?([:claimed, :completed, :canceled], pick.status)
  end

  def show_team_class(%Pick{} = pick) do
    if show_team?(pick) do
      "padding-pick-l"
    end
  end

  def is_cancelable?(%Pick{} = pick) do
    Enum.member?([:submitted, :scheduled, :claimed, :rescheduled], pick.status)
  end

  def cancel_options do
    [
      {"I Have A Scheduling Conflict", "I Have A Scheduling Conflict"},
      {"My Fruit Has Already Fallen Off The Tree", "My Fruit Has Already Fallen Off The Tree"},
      {"My Fruit Isn’t Ripe", "My Fruit Isn’t Ripe"},
      {"My Fruit Has Bugs", "My Fruit Has Bugs"},
      {"My Fruit Is Rotten", "My Fruit Is Rotten"}
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

  def show_pick_report?(pick) do
    pick.report && pick.report.is_complete
  end

  def am_lead_picker?(%Pick{} = pick, %Person{} = person) do
    pick.lead_picker_id == person.id
  end

  def fruit_quality_options do
    [
      {"Perfect", "perfect"},
      {"Good", "good"},
      {"Okay", "okay"},
      {"Has Imperfections", "has imperfections"},
      {"Poor", "poor"}
    ]
  end

  def get_field(form, field) do
    Ecto.Changeset.get_field(form.source, String.to_existing_atom(field))
  end
end
