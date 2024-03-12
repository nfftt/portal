defmodule FruitPickerWeb.EditPickReportLive do
  use FruitPickerWeb, :live_view

  alias FruitPicker.Activities
  alias FruitPicker.Activities.PickReport

  def mount(_, %{"pick_id" => pick_id}, socket) do
    pick = Activities.get_pick!(pick_id)
    report = pick.report

    pick_report_changeset = PickReport.changeset(report, %{})

    {:ok, assign(socket, pick: pick, pick_report_changeset: pick_report_changeset)}
  end

  def handle_event("submit", %{"pick_report" => attrs}, socket) do
    case Activities.update_report(socket.assigns.pick.report.id, attrs) do
      {:error, changeset} ->
        {:noreply, assign(socket, pick_report_changeset: changeset)}

      {:ok, _} ->
        {:noreply,
         push_redirect(socket, to: Routes.admin_pick_path(socket, :show, socket.assigns.pick.id))}
    end
  end
end
