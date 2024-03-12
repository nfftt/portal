defmodule FruitPickerWeb.AvatarController do
  use FruitPickerWeb, :controller

  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.Person
  alias FruitPickerWeb.AvatarController

  def edit(conn, _params) do
    person = conn.assigns.current_person

    changeset = Accounts.change_avatar(person)
    render(
      conn,
      "edit.html",
      person: person,
      changeset: changeset
    )
  end

  def update(conn, %{"person" => person_params}) do
    person = conn.assigns.current_person

    case Accounts.update_avatar(person, person_params) do
      {:ok, person} ->
        conn
        |> put_flash(:info, "Your profile picture was updated successfully.")
        |> redirect(to: Routes.profile_path(conn, :show))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "edit.html",
          person: person,
          changeset: changeset,
        )
    end
  end
end
