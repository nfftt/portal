defmodule FruitPickerWeb.Plugs.Auth do
  @moduledoc """
  Provides functions for authenticating a connection.
  """

  @behaviour Plug
  import Plug.Conn

  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.Person

  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, repo) do
    person_id = get_session(conn, :person_id)

    try do
      person = person_id && Accounts.get_person!(person_id)
      setup_sentry_context(person)
      assign(conn, :current_person, person)
    rescue
      Ecto.NoResultsError ->
        signout(conn)
    end
  end

  def signin(conn, person) do
    conn
    |> assign(:current_person, person)
    |> put_session(:person_id, person.id)
    |> configure_session(renew: false)

    # TODO: confirm that `renew: true` means that the
    # session will persist and that this will work for the
    # "remember me" functionality
    # |> configure_session(renew: true)
  end

  def login_by_email_and_pass(conn, email, given_pass, opts) do
    repo = Keyword.fetch!(opts, :repo)
    person = repo.get_by(Person, email: email)

    cond do
      person && Accounts.get_person_by_email_and_password(email, given_pass) ->
        {:ok, signin(conn, person)}

      person ->
        {:error, :unauthorized, conn}

      true ->
        {:error, :unauthorized, conn}
    end
  end

  defp signout(conn) do
    conn
    |> configure_session(drop: true)
    |> delete_session(:person_id)
  end

  defp setup_sentry_context(%Person{} = person) do
    if Application.get_env(:fruit_picker, :sentry_dsn) do
      Sentry.Context.set_user_context(%{
        id: person.id,
        username: "#{person.first_name} #{person.last_name}",
        email: person.email,
        membership_is_active: person.membership_is_active
      })
    end
  end

  defp setup_sentry_context(person) do
    # nothing to do, maybe log
  end
end
