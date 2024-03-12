defmodule FruitPicker.ActivitiesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FruitPicker.Activities` context.
  """
  alias FruitPicker.Activities

  @doc """
  Generate a pick.
  """
  def pick_fixture(attrs \\ %{}, tree_owner, tree) do
    {:ok, pick} =
      attrs
      |> Enum.into(%{
        "tree_owner_takes" => "1/3",
        "start_date" => Date.utc_today(),
        "end_date" => Date.add(Date.utc_today(), 3),
        "ladder_provided" => "true",
        "pick_time_any" => true,
        "pick_time_morning" => true,
        "pick_time_afternoon" => true,
        "pick_time_evening" => true
      })
      |> Activities.admin_create_pick(tree_owner, [tree])

    Activities.get_pick!(pick.id)
  end

  def scheduled_pick_fixture(
        start_datetime \\ nil,
        end_datetime \\ nil,
        pick_attrs \\ %{},
        tree_owner,
        tree
      ) do
    start_datetime =
      if is_nil(start_datetime) do
        DateTime.add(DateTime.utc_now(), 6, :hour)
      else
        start_datetime
      end

    end_datetime =
      if is_nil(end_datetime) do
        DateTime.add(start_datetime, 2, :hour)
      else
        end_datetime
      end

    pick_attrs =
      Enum.into(pick_attrs, %{
        "start_date" => start_datetime |> DateTime.add(-1, :day) |> DateTime.to_date(),
        "end_date" => start_datetime |> DateTime.add(2, :day) |> DateTime.to_date()
      })

    pick = pick_fixture(pick_attrs, tree_owner, tree)

    schedule_attrs = %{
      "scheduled_date" => DateTime.to_date(start_datetime) |> Date.to_string(),
      "scheduled_start_time" => DateTime.to_time(start_datetime) |> Time.to_string(),
      "scheduled_end_time" => DateTime.to_time(end_datetime) |> Time.to_string()
    }

    Activities.admin_update_pick(pick, [tree], schedule_attrs)

    Activities.get_pick!(pick.id)
  end
end
