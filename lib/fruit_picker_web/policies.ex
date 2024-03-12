defmodule FruitPickerWeb.Policies do
  @moduledoc """
  Policies manage authorization for which parts of the portal users can access.
  """

  # set up support for policies
  use PolicyWonk.Policy
  # turn this module into an enforcement plug
  use PolicyWonk.Enforce
  use FruitPickerWeb, :controller

  alias FruitPicker.Accounts.Person
  alias FruitPickerWeb.ErrorHandlers
  alias FruitPicker.Activities

  def policy(assigns, :current_person) do
    case assigns[:current_person] do
      %Person{} ->
        :ok

      _ ->
        {:error, :current_person}
    end
  end

  def policy_error(conn, :current_person) do
    ErrorHandlers.unauthenticated(conn, "You must be logged in to view that page.")
  end

  def policy(assigns, :active_membership) do
    if assigns.current_person.membership_is_active do
      :ok
    else
      {:error, :no_active_membership}
    end
  end

  def policy_error(conn, :no_active_membership) do
    ErrorHandlers.inactive(
      conn,
      "Your account is inactive. Please pay your membership fee to access this feature."
    )
  end

  def policy(assigns, :no_current_person) do
    case assigns[:current_person] do
      %Person{} ->
        {:error, :no_current_person}

      _ ->
        :ok
    end
  end

  def policy(assigns, :waiver_consent_tree_owner) do
    person = assigns.current_person

    if person.is_tree_owner and not person.accepts_consent_tree_owner do
      {:error, :no_consent}
    else
      :ok
    end
  end

  def policy(assigns, :tree_owner_has_requested_pick) do
    person = assigns.current_person

    cond do
      not person.is_tree_owner ->
        :ok

      has_made_pick_request(person.id) ->
        :ok

      true ->
        {:error, :tree_owner_no_picks_requested}
    end
  end

  defp has_made_pick_request(person_id) do
    Activities.tree_owner_has_requested_pick?(person_id)
  end

  def policy_error(conn, :tree_owner_no_picks_requested) do
    ErrorHandlers.tree_owner_no_picks_requested(conn, "")
  end

  def policy(assigns, :waiver_consent_picker) do
    person = assigns.current_person

    if person.is_picker and not person.accepts_consent_picker do
      {:error, :no_consent}
    else
      :ok
    end
  end

  def policy_error(conn, :no_consent) do
    ErrorHandlers.no_consent(
      conn,
      "You must read and agree to the consent waiver before participating in picks."
    )
  end

  def policy_error(conn, :no_current_person) do
    ErrorHandlers.has_user(conn, "Please sign out before continuing.")
  end

  def policy(assigns, :is_admin) do
    case is_admin(assigns.current_person) do
      true ->
        :ok

      _ ->
        {:error, :not_admin}
    end
  end

  def policy_error(conn, :not_admin) do
    ErrorHandlers.not_admin(conn, "You do not have the proper role to view that page.")
  end

  def policy(assigns, :is_lead_picker) do
    case is_lead_picker(assigns.current_person) do
      true ->
        :ok

      _ ->
        {:error, :not_lead_picker}
    end
  end

  def policy_error(conn, :not_lead_picker) do
    ErrorHandlers.not_lead_picker(conn, "You do not have the proper role to view that page.")
  end

  def policy(assigns, :is_lead_picker_or_admin) do
    cond do
      is_lead_picker(assigns.current_person) ->
        :ok

      is_admin(assigns.current_person) ->
        :ok

      true ->
        {:error, :not_lead_picker_or_admin}
    end
  end

  def policy_error(conn, :not_lead_picker_or_admin) do
    ErrorHandlers.not_lead_picker(conn, "You do not have the proper role to view that page.")
  end

  def policy(assigns, :is_tree_owner) do
    case is_tree_owner(assigns.current_person) do
      true ->
        :ok

      _ ->
        {:error, :not_tree_owner}
    end
  end

  def policy_error(conn, :not_tree_owner) do
    ErrorHandlers.not_tree_owner(conn, "You do not have the proper role to view that page.")
  end

  def policy(assigns, :is_picker) do
    case is_picker(assigns.current_person) do
      true ->
        :ok

      _ ->
        {:error, :not_picker}
    end
  end

  def policy(assigns, :is_user) do
    case is_user(assigns.current_person) do
      true ->
        :ok

      _ ->
        {:error, :not_user}
    end
  end

  def policy_error(conn, :not_user) do
    ErrorHandlers.not_user(conn, "You do not have the proper role to view that page.")
  end

  def policy_error(conn, :not_picker) do
    ErrorHandlers.not_picker(conn, "You do not have the proper role to view that page.")
  end

  def policy(assigns, :is_agency) do
    case is_agency(assigns.current_person) do
      true ->
        :ok

      _ ->
        {:error, :not_agency}
    end
  end

  def policy_error(conn, :not_agency) do
    ErrorHandlers.not_agency(conn, "you is not an agency")
  end

  def policy(assigns, :not_agency) do
    case not_agency(assigns.current_person) do
      true ->
        :ok

      _ ->
        {:error, :is_agency}
    end
  end

  def policy_error(conn, :is_agency) do
    ErrorHandlers.is_agency(conn, "You do not have the proper role to view that page.")
  end

  def policy(assigns, :no_outstanding_reports) do
    cp = assigns.current_person

    if is_lead_picker(cp) and Activities.picks_with_outstanding_report(cp) |> length() > 0 do
      {:error, :outstanding_report}
    else
      :ok
    end
  end

  def policy_error(conn, :outstanding_report) do
    if conn.assigns[:pick] do
      conn
      |> put_flash(
        :error,
        "Please fill out your oustanding pick report before participating in other picks."
      )
      |> redirect(to: Routes.pick_path(conn, :show, conn.assigns.pick))
    else
      conn
      |> put_flash(
        :error,
        "Please fill out your oustanding pick report before participating in other picks."
      )
      |> redirect(to: Routes.dashboard_path(conn, :index))
    end
  end

  defp is_admin(nil), do: false
  defp is_admin(actor), do: Person.is_admin(actor)
  defp is_picker(nil), do: false
  defp is_picker(actor), do: actor.is_picker
  defp is_lead_picker(nil), do: false
  defp is_lead_picker(actor), do: actor.is_lead_picker
  defp is_tree_owner(nil), do: false
  defp is_tree_owner(actor), do: actor.is_tree_owner
  defp is_picker(nil), do: false
  defp is_picker(actor), do: actor.is_picker
  defp is_agency(nil), do: false
  defp is_agency(actor), do: Person.is_agency(actor)
  defp not_agency(nil), do: false
  defp not_agency(actor), do: Person.not_agency(actor)
  defp is_user(nil), do: false
  defp is_user(actor), do: Person.is_user(actor)
end
