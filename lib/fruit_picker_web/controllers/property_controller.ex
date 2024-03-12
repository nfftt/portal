defmodule FruitPickerWeb.PropertyController do
  use FruitPickerWeb, :controller

  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.Property
  alias FruitPicker.Mailchimp
  alias FruitPickerWeb.Policies

  plug(Policies, :is_tree_owner)

  def index(conn, _params) do
    person = conn.assigns.current_person

    try do
      Accounts.get_my_property!(person)
    rescue
      Ecto.NoResultsError ->
        conn
        |> redirect(to: Routes.property_path(conn, :new))

      Ecto.MultipleResultsError ->
        conn
        |> put_flash(
          :error,
          "There was a problem retrieving your property information, please contact support."
        )
        |> redirect(to: Routes.dashboard_path(conn, :index))
    end

    property = Accounts.get_my_property(person)

    render(
      conn,
      "index.html",
      property: property,
      trees: property.trees
    )
  end

  def new(conn, _params) do
    person = conn.assigns.current_person
    changeset = Accounts.change_property(%Property{})

    try do
      property = Accounts.get_my_property!(person)

      conn
      |> redirect(to: Routes.property_path(conn, :index))
    rescue
      Ecto.NoResultsError ->
        render(
          conn,
          "new.html",
          changeset: changeset
        )

      Ecto.MultipleResultsError ->
        conn
        |> put_flash(
          :error,
          "There was a problem retrieving your property information, please contact support."
        )
        |> redirect(to: Routes.dashboard_path(conn, :index))
    end
  end

  def create(conn, %{"property" => property_params}) do
    person = conn.assigns.current_person

    try do
      Accounts.get_my_property!(person)

      redirect(conn, to: Routes.property_path(conn, :index))
    rescue
      Ecto.NoResultsError ->
        case Accounts.create_property(property_params, person) do
          {:ok, property} ->
            if property.is_in_operating_area do
              Task.start(fn ->
                Mailchimp.remove_oooa_tag_to_tree_owner(person.email)
              end)

              conn
              |> put_flash(:success, "Your property details were successfully saved.")
              |> redirect(to: Routes.profile_path(conn, :show, payment: true))
            else
              Task.start(fn ->
                Mailchimp.add_oooa_tag_to_tree_owner(person.email)
              end)

              conn
              |> put_flash(:success, "Your property details were successfully saved.")
              |> redirect(to: Routes.property_path(conn, :index))
            end

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_flash(:error, "There was a problem saving your profile.")
            |> render(
              "new.html",
              changeset: changeset,
              person: person
            )
        end

      Ecto.MultipleResultsError ->
        conn
        |> put_flash(
          :error,
          "There was a problem retrieving your property information, please contact support."
        )
        |> redirect(to: Routes.dashboard_path(conn, :index))
    end
  end

  def edit(conn, _params) do
    person = conn.assigns.current_person

    try do
      property = Accounts.get_my_property!(person)

      changeset = Accounts.change_property(property)

      render(
        conn,
        "edit.html",
        changeset: changeset
      )
    rescue
      Ecto.MultipleResultsError ->
        conn
        |> put_flash(
          :error,
          "There was a problem retrieving your property information, please contact support."
        )
        |> redirect(to: Routes.dashboard_path(conn, :index))
    end
  end

  def update(conn, %{"property" => property_params}) do
    property = Accounts.get_my_property(conn.assigns.current_person)

    case Accounts.update_property(property, property_params) do
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
        |> redirect(to: Routes.property_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem saving your profile.")
        |> render(
          "edit.html",
          changeset: changeset
        )
    end
  end
end
