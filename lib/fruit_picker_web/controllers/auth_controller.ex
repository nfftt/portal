defmodule FruitPickerWeb.AuthController do
  @moduledoc """
    Actions for logging into the portal.
  """

  use FruitPickerWeb, :controller
  plug Ueberauth

  alias FruitPicker.{Repo, Accounts}
  alias FruitPicker.Accounts.Person
  alias FruitPickerWeb.{FallbackController, Router}
  alias FruitPickerWeb.Plugs.Auth
  alias Ueberauth.Strategy.Helpers

  action_fallback FallbackController

  @doc """
    Display the signin page.
  """
  def request(%{assigns: %{current_person: %Person{} = current_person}} = conn, _params) do
    conn
    |> redirect(to: Router.Helpers.dashboard_path(conn, :index))
  end

  def request(conn, _params) do
    changeset = Person.signin_changeset(%Person{}, %{})
    conn
    |> render("request.html", callback_url: Helpers.callback_url(conn), changeset: changeset)
  end

  def signin(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> render("request.html", callback_url: Helpers.callback_url(conn))
  end

  def signin(%{assigns: %{ueberauth_auth: %{uid: email, credentials: %{other: %{password: password}}}}} = conn, _params) do
    case Accounts.get_person_by_email_and_password(email, password) do
      {:ok, person} ->
        conn
        |> Auth.signin(person)
        |> redirect(to: Router.Helpers.dashboard_path(conn, :index))
      {:error, reason} ->
        conn
        |> put_flash(:error, "There was a problem signing in. Please try again.")
        |> render("request.html", callback_url: Helpers.callback_url(conn))
    end
  end

  def forgot(conn, _) do
    render(conn, "forgot.html")
  end

  def forgot_request(conn, %{"forgot" => %{"email" => email}}) do
    email = email
    |> String.downcase()
    |> String.trim()

    Accounts.provide_password_reset_token(email)

    # do not leak info about (non-)existing users.
    # always reply with a success message

    conn
    |> assign(:email, email)
    |> render("forgot_success.html")
  end

  def new_password(conn, %{"token_value" => token_value}) do
    case Accounts.verify_token_value(token_value) do
      {:ok, person} ->
        conn
        |> assign(:token_value, token_value)
        |> assign(:changeset, Person.password_changeset(%Person{}, %{}))
        |> render("new_password.html")

      {:error, _reason} ->
        {:error, :not_found}
    end
  end

  def create_password(conn, %{"password" => password_params, "token_value" => token_value}) do
    case Accounts.create_password(password_params, token_value) do
      {:ok, _person} ->
        conn
        |> render("new_password_success.html")
      {:error, :not_found} ->
        {:error, :not_found}
      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem saving your new password.")
        |> render("new_password.html", changeset: changeset, token_value: token_value)
    end
  end

  def signout(conn, _params) do
    conn
    |> put_flash(:info, "You have been signed out!")
    |> configure_session(drop: true)
    |> delete_session(:person_id)
    |> redirect(to: Router.Helpers.auth_path(conn, :request))
  end
end
