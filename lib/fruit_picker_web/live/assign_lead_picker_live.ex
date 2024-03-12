defmodule FruitPickerWeb.AssignLeadPickerLive do
  use FruitPickerWeb, :live_view

  alias FruitPicker.Activities.Pick

  alias FruitPicker.{
    Activities,
    Inventory,
    Partners,
    Accounts
  }

  def mount(_params, %{"pick" => pick}, socket) do
    changeset = Pick.admin_assign_lead_picker_changeset(pick, %{})

    socket =
      assign(socket,
        changeset: changeset,
        pick: pick,
        equipment_sets: get_equipment_sets(),
        agencies: get_agencies(),
        lead_pickers: get_lead_pickers(),
        scheduled_end_time: nil
      )

    {:ok, socket}
  end

  def handle_event("change", %{"pick" => pick, "_target" => target}, socket) do
    %{"scheduled_start_time" => scheduled_start_time, "scheduled_date" => scheduled_date} = pick
    [_, field] = target

    if String.length(scheduled_date) > 0 && String.length(scheduled_start_time) > 0 &&
         (field == "scheduled_date" or field == "scheduled_start_time") do
      scheduled_end_time = get_end_time(scheduled_start_time)

      changeset = Pick.admin_assign_lead_picker_changeset(socket.assigns.pick, pick)

      socket =
        socket
        |> assign(
          changeset: changeset,
          equipment_sets: get_equipment_sets(scheduled_date, scheduled_start_time),
          agencies: get_agencies(scheduled_date, scheduled_start_time),
          scheduled_end_time: scheduled_end_time
        )

      {:noreply, socket}
    else
      changeset = Pick.admin_assign_lead_picker_changeset(socket.assigns.pick, pick)

      {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("submit", %{"pick" => pick_params}, socket) do
    case Activities.assign_lead_picker(socket.assigns.pick, pick_params) do
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:ok, pick} ->
        {:noreply, push_redirect(socket, to: Routes.admin_pick_path(socket, :show, pick.id))}
    end
  end

  defp get_equipment_sets(scheduled_date, scheduled_start_time) do
    Inventory.list_equipment_sets_available(scheduled_date, scheduled_start_time)
    |> generate_options()
  end

  defp get_equipment_sets() do
    Inventory.list_equipment_sets(:active)
    |> generate_options()
  end

  defp get_agencies(scheduled_date, scheduled_start_time) do
    Partners.list_agencies_available(scheduled_date, scheduled_start_time)
    |> generate_options()
  end

  defp get_agencies() do
    Partners.list_agencies() |> generate_options()
  end

  def get_lead_pickers do
    Accounts.list_sorted_lead_pickers() |> generate_lead_picker_options()
  end

  defp generate_options(list) do
    Enum.map(list, &{"#{&1.name} (#{&1.closest_intersection})", &1.id})
  end

  defp generate_lead_picker_options(list) do
    Enum.map(list, &{"#{&1.first_name} #{&1.last_name} (#{&1.id})", &1.id})
  end

  defp get_end_time(time) do
    [hours, minutes, _] = String.split(time, ":")
    hours = String.to_integer(hours) + 2

    h = rem(hours, 12)

    "#{if h == 0, do: 12, else: h}:#{minutes} #{if hours < 12, do: "AM", else: "PM"}"
  end
end
