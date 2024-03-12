defmodule FruitPickerWeb.ProfileController do
  use FruitPickerWeb, :controller

  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.{Person, Profile}
  alias FruitPickerWeb.{PersonController, Policies}

  import Logger

  def show(conn, params) do
    person = conn.assigns.current_person
    go_to_payment = Map.get(params, "payment", false)

    case create_stripe_session(conn, person) do
      {:ok, stripe_session} ->
        render(conn, "show.html",
          stripe_session_id: stripe_session.id,
          stripe_pub_key: Application.get_env(:fruit_picker, :stripe_pub_key),
          go_to_payment: go_to_payment,
          person: person
        )

      {:error, %Stripe.Error{} = error} ->
        Logger.error(error.message)

        render(conn, "show.html",
          stripe_session_id: nil,
          stripe_pub_key: Application.get_env(:fruit_picker, :stripe_pub_key),
          go_to_payment: go_to_payment,
          person: person
        )
    end
  end

  def setup(conn, _params) do
    person = conn.assigns.current_person
    profile_changeset = Accounts.change_profile(%Profile{})
    Map.put(person, :profile, profile_changeset)
    person_changeset = Accounts.change_person(person)

    render(
      conn,
      "edit.html",
      changeset: person_changeset
    )
  end

  def edit(conn, _params) do
    person = conn.assigns.current_person

    if person.profile do
      changeset = Accounts.change_person(person)

      render(
        conn,
        "edit.html",
        person: person,
        changeset: changeset
      )
    else
      conn
      |> redirect(to: Routes.profile_path(conn, :setup))
    end
  end

  def update(conn, %{"person" => person_params}) do
    person = conn.assigns.current_person

    case Accounts.update_person(person, person_params) do
      {:ok, person} ->
        conn
        |> put_flash(:info, "Your profile was updated successfully.")
        |> redirect(to: Routes.profile_path(conn, :show))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "edit.html",
          person: person,
          changeset: changeset
        )
    end
  end

  def payment_thanks(conn, _params) do
    person = conn.assigns.current_person

    if person.is_tree_owner do
      conn
      |> put_flash(
        :success,
        "Thank you for your memberhsip payment! Please input your property details and add your fruit tree(s) now."
      )
      |> redirect(to: Routes.property_path(conn, :index))
    else
      conn
      |> put_flash(:success, "Thank you for your membership payment! Your account is now active.")
      |> redirect(to: Routes.dashboard_path(conn, :index))
    end
  end

  defp create_stripe_session(conn, %Person{} = person) do
    if person.is_tree_owner do
      Stripe.Session.create(%{
        cancel_url: Routes.profile_url(conn, :show),
        payment_method_types: ["card"],
        success_url: Routes.profile_url(conn, :payment_thanks),
        customer_email: person.email,
        billing_address_collection: "required",
        line_items: [
          %{
            amount: 4000,
            currency: "CAD",
            name: "Tree Owner Membership",
            quantity: 1
          }
        ]
      })
    else
      Stripe.Session.create(%{
        cancel_url: Routes.profile_url(conn, :show),
        payment_method_types: ["card"],
        success_url: Routes.profile_url(conn, :payment_thanks),
        customer_email: person.email,
        billing_address_collection: "required",
        line_items: [
          %{
            amount: 1000,
            currency: "CAD",
            name: "Fruit Picker Membership",
            quantity: 1
          }
        ]
      })
    end
  end
end
