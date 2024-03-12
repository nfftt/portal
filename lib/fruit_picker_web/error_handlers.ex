defmodule FruitPickerWeb.Errors.ForbiddenError do
  defexception message: "You do not have access to this resource.",
               plug_status: 403
end

defmodule FruitPickerWeb.Errors.NotFoundError do
  defexception message: "This resource cannot be found.",
               plug_status: 404
end

defmodule FruitPickerWeb.ErrorHandlers do
  @moduledoc """
  Handles policy errors for loading and enforcing resources
  and more fine grained policies.
  """

  use FruitPickerWeb, :controller
  alias FruitPickerWeb.{Errors, ErrorView, Router}

  @doc """
  Handle a resource not existing by showing the 404 page.
  """
  def resource_error(conn, _message) do
    handle_error(conn, :not_found)
  end

  @doc """
  Handle the case where an authenticated user is not present by
  displaying an error message and showing the sign in page.
  """
  def unauthenticated(conn, message) do
    handle_error(conn, :unauthenticated, message)
  end

  def has_user(conn, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: Routes.dashboard_path(conn, :index))
  end

  def inactive(conn, message) do
    handle_error(conn, :unauthorized, message)
  end

  def not_admin(conn, _message) do
    handle_error(conn, :unauthorized)
  end

  def not_agency(conn, _message) do
    handle_error(conn, :unauthorized)
  end

  def is_agency(conn, _message) do
    handle_error(conn, :unauthorized)
  end

  def not_picker(conn, message) do
    handle_error(conn, :unauthorized, message)
  end

  def not_picker(conn, _message) do
    handle_error(conn, :unauthorized)
  end

  def not_volunteer(conn, message) do
    handle_error(conn, :unauthorized, message)
  end

  def not_volunteer(conn, _message) do
    handle_error(conn, :unauthorized)
  end

  def not_user(conn, message) do
    handle_error(conn, :unauthorized, message)
  end

  def not_user(conn, _message) do
    handle_error(conn, :unauthorized)
  end

  def not_lead_picker(conn, _message) do
    handle_error(conn, :unauthorized)
  end

  def not_lead_picker_or_admin(conn, _message) do
    handle_error(conn, :unauthorized)
  end

  def not_tree_owner(conn, _message) do
    handle_error(conn, :unauthorized)
  end

  def not_volunteer(conn, _message) do
    handle_error(conn, :unauthorized)
  end

  def tree_owner_no_picks_requested(conn, _message) do
    message = "Thanks for setting up your property. Please submit a pick request next."

    conn
    |> put_flash(:info, message)
    |> redirect(to: Router.Helpers.pick_path(conn, :new))
  end

  def forbidden(conn, message) do
    handle_error(conn, :unauthorized, message)
  end

  def no_consent(conn, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: Router.Helpers.profile_path(conn, :edit))
  end

  defp handle_error(conn, :not_found) do
    raise Errors.NotFoundError
  end

  defp handle_error(conn, :unauthorized) do
    raise Errors.ForbiddenError
  end

  defp handle_error(conn, :unauthorized, message) do
    raise Errors.ForbiddenError, message: message
  end

  defp handle_error(conn, :unauthenticated, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: Router.Helpers.auth_path(conn, :request))
  end
end
