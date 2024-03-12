defmodule FruitPickerWeb.Admin.PropertyController do
  use FruitPickerWeb, :controller

  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.Property
  alias FruitPicker.Mailchimp
  alias FruitPickerWeb.Policies

  def setup(conn, %{"id" => person_id}) do
    person = Accounts.get_person!(person_id)
    changeset = Accounts.change_property(%Property{})

    try do
      Accounts.get_my_property!(person)

      redirect(conn, to: Routes.admin_property_path(conn, :edit, person))
    rescue
      Ecto.NoResultsError ->
        render(
          conn,
          "setup.html",
          person: person,
          changeset: changeset
        )

      Ecto.MultipleResultsError ->
        conn
        |> put_flash(
          :error,
          "There was a problem retrieving the property information, please contact tech support."
        )
        |> redirect(to: Routes.dashboard_path(conn, :index))
    end
  end

  def show(conn, %{"id" => person_id}) do
    person = Accounts.get_person!(person_id)

    try do
      Accounts.get_my_property!(person)
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_flash(
          :error,
          "This person doesn't have their property data setup. Please complete this first."
        )
        |> redirect(to: Routes.admin_property_path(conn, :setup, person))

      Ecto.MultipleResultsError ->
        conn
        |> put_flash(
          :error,
          "There was a problem retrieving the property information, please contact tech support."
        )
        |> redirect(to: Routes.dashboard_path(conn, :index))
    end

    property = Accounts.get_my_property(person)

    render(
      conn,
      "show.html",
      property: property,
      person: person,
      trees: property.trees
    )
  end

  def create(conn, %{"id" => person_id, "property" => property_params}) do
    person = Accounts.get_person!(person_id)

    case Accounts.create_property(property_params, person) do
      {:ok, property} ->
        if property.is_in_operating_area do
          Task.start(fn ->
            Mailchimp.remove_oooa_tag_to_tree_owner(person.email)
          end)
        else
          Task.start(fn ->
            Mailchimp.add_oooa_tag_to_tree_owner(person.email)
          end)
        end

        conn
        |> put_flash(:success, "The property details were successfully updated.")
        |> redirect(to: Routes.admin_property_path(conn, :show, person))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem saving the property.")
        |> render(
          "edit.html",
          changeset: changeset,
          person: person
        )
    end
  end

  def edit(conn, %{"id" => person_id}) do
    person = Accounts.get_person!(person_id)
    property = Accounts.get_my_property(person)

    if property do
      changeset = Accounts.change_property(property)

      render(
        conn,
        "edit.html",
        person: person,
        changeset: changeset
      )
    else
      redirect(conn, to: Routes.admin_property_path(conn, :setup, person))
    end
  end

  def update(conn, %{"id" => person_id, "property" => property_params}) do
    person = Accounts.get_person!(person_id)
    property = Accounts.get_my_property(person)

    case Accounts.admin_update_property(property, property_params) do
      {:ok, property} ->
        if property.is_in_operating_area do
          Task.start(fn ->
            Mailchimp.remove_oooa_tag_to_tree_owner(property.person.email)
          end)
        else
          Task.start(fn ->
            Mailchimp.add_oooa_tag_to_tree_owner(property.person.email)
          end)
        end

        conn
        |> put_flash(:info, "Property details updated successfully.")
        |> redirect(to: Routes.admin_property_path(conn, :show, person))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem saving your property.")
        |> render(
          "edit.html",
          person: person,
          changeset: changeset
        )
    end
  end
end
