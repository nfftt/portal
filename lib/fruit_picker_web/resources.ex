defmodule FruitPickerWeb.Resources do
  @moduledoc """
  Load resources with policy-like control over restricting access.
  """

  use PolicyWonk.Resource
  use PolicyWonk.Load

  alias FruitPicker.Activities
  alias FruitPickerWeb.ErrorHandlers

  def resource(conn, :pick, %{"id" => pick_id}) do
    person = conn.assigns.current_person
    pick = Activities.get_pick!(pick_id)

    cond do
      person.is_tree_owner and pick.requester_id == person.id ->
        {:ok, :pick, pick}
      person.is_lead_picker and pick.lead_picker_id == person.id ->
        {:ok, :pick, pick}
      pick.is_private ->
        ErrorHandlers.forbidden(conn, "You are not allowed to view this pick.")
        {:error, "cannot view pick"}
      person in pick.pickers ->
        {:ok, :pick, pick}
      pick.status in [:scheduled, :claimed, :rescheduled] ->
        {:ok, :pick, pick}
      true ->
        ErrorHandlers.forbidden(conn, "You are not allowed to view this pick.")
        {:error, "cannot view pick"}
    end
  end

  def resource_error(conn, message) do
    ErrorHandlers.forbidden(conn, message)
  end
end
