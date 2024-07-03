defmodule FruitPickerWeb.RegisterController do
  use FruitPickerWeb, :controller

  alias FruitPicker.{Mailchimp, Mailer, Repo}
  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.{Person, Profile}
  alias FruitPickerWeb.Plugs.Auth
  alias FruitPickerWeb.{Email, PersonController, Policies}

  plug(Policies, :no_current_person)

  def new(conn, %{"account_type" => account_type}) do
    if account_type in ["fruit_picker", "tree_owner"] do
      profile_changeset = Accounts.change_profile(%Profile{})
      person_changeset = Accounts.change_person(%Person{profile: profile_changeset})

      render(
        conn,
        "form.html",
        changeset: person_changeset,
        account_type: account_type
      )
    else
      conn
      |> put_flash(:error, "Sorry, that is not a valid account type.")
      |> redirect(to: Routes.register_path(conn, :new))
    end
  end

  def new(conn, _params) do
    changeset = Accounts.change_person(%Person{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"account_type" => account_type, "person" => person_params}) do
    case Accounts.create_person(person_params, account_type) do
      {:ok, person} ->
        email_admins_new_registration(person, account_type)
        Mailchimp.subscribe(person, account_type)

        conn
        |> Auth.signin(person)
        |> welcome_person(person)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem completing the registration.")
        |> render(
          "form.html",
          changeset: changeset,
          account_type: account_type
        )
    end
  end

  defp welcome_person(conn, person) do
    cond do
      person.is_picker ->
        conn
        |> put_flash(
          :info,
          "Thanks for registering with NFFTT! Please complete your season membership payment to continue."
        )
        |> redirect(to: Routes.profile_path(conn, :show, payment: true))

      person.is_tree_owner ->
        conn
        |> put_flash(
          :info,
          "Thanks for registering with NFFTT! Please setup your property and trees next."
        )
        |> redirect(to: Routes.property_path(conn, :new))

      true ->
        conn
        |> redirect(to: Routes.profile_path(conn, :show))
    end
  end

  defp email_admins_new_registration(%Person{} = person, role) do
    admins =
      Person.admins()
      |> Person.active()
      |> Repo.all()

    role = Recase.to_title(role)

    Enum.each(admins, fn a ->
      a
      |> Email.new_registration(person, role)
      |> Mailer.deliver_later()
    end)
  end
end
