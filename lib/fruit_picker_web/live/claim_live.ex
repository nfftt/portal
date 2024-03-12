defmodule FruitPickerWeb.ClaimLive do
  use FruitPickerWeb, :live_view
  alias FruitPickerWeb.{EmailView, PickView, SharedView}

  alias FruitPicker.Inventory

  alias FruitPicker.Activities.Pick
  alias FruitPicker.Partners

  def mount(_params, %{"changeset" => changeset, "pick" => pick}, socket) do
    equipment_sets =
      Inventory.list_equipment_sets(:active)
      |> generate_options()

    agencies = Partners.list_agencies() |> generate_options()

    socket =
      assign(socket,
        changeset: changeset,
        pick: pick,
        equipment_sets: equipment_sets,
        agencies: agencies,
        scheduled_end_time: nil
      )

    {:ok, socket}
  end

  def handle_event("change", %{"pick" => pick, "_target" => target}, socket) do
    %{"scheduled_start_time" => scheduled_start_time, "scheduled_date" => scheduled_date} = pick
    [_, field] = target

    updated_changeset = Pick.claim_changeset(socket.assigns.pick, pick)

    if String.length(scheduled_date) > 0 && String.length(scheduled_start_time) > 0 &&
         (field == "scheduled_date" or field == "scheduled_start_time") do
      equipment_sets =
        Inventory.list_equipment_sets_available(scheduled_date, scheduled_start_time)
        |> generate_options()

      agencies =
        Partners.list_agencies_available(scheduled_date, scheduled_start_time)
        |> generate_options()

      {:noreply,
       assign(socket,
         equipment_sets: equipment_sets,
         changeset: updated_changeset,
         agencies: agencies,
         scheduled_end_time: get_end_time(scheduled_start_time)
       )}
    else
      {:noreply, socket}
    end
  end

  defp generate_options(list) do
    Enum.map(list, &{"#{&1.name} (#{&1.closest_intersection})", &1.id})
  end

  defp get_end_time(time) do
    [hours, minutes, _] = String.split(time, ":")
    hours = String.to_integer(hours) + 2

    h = rem(hours, 12)

    "#{if h == 0, do: 12, else: h}:#{minutes} #{if hours < 12, do: "AM", else: "PM"}"
  end
end
