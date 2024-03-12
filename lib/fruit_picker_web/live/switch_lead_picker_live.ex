defmodule FruitPickerWeb.SwitchLeadPickerLive do
  use FruitPickerWeb, :live_view

  alias FruitPicker.Activities.Pick

  alias FruitPicker.{
    Activities,
    Inventory,
    Partners,
    Accounts
  }

  def mount(_params, %{"pick" => pick}, socket) do
    changeset = Pick.admin_switch_lead_picker_changeset(pick, %{})

    socket =
      assign(socket,
        changeset: changeset,
        pick: pick,
        lead_pickers: get_lead_pickers()
      )

    {:ok, socket}
  end

  def handle_event("submit", %{"pick" => pick_params}, socket) do
    case Activities.assign_lead_picker(socket.assigns.pick, pick_params) do
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:ok, pick} ->
        {:noreply, push_redirect(socket, to: Routes.admin_pick_path(socket, :show, pick.id))}
    end
  end

  def get_lead_pickers do
    Accounts.list_sorted_lead_pickers() |> generate_lead_picker_options()
  end

  defp generate_lead_picker_options(list) do
    Enum.map(list, &{"#{&1.first_name} #{&1.last_name} (#{&1.id})", &1.id})
  end
end
