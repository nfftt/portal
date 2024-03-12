defmodule FruitPickerWeb.Admin.PaymentController do
  @moduledoc false

  use FruitPickerWeb, :controller

  alias FruitPicker.{Mailer, Repo}
  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.{
    Person,
    Tree,
    TreeSnapshot
  }
  alias FruitPicker.Accounts.MembershipPayment

  def new(conn, %{"id" => id}) do
    person = Accounts.get_person!(id)

    changeset = MembershipPayment.changeset(%MembershipPayment{}, %{})
    render(conn, "new.html",
      person: person,
      changeset: changeset,
    )
  end

  def create(conn, %{"membership_payment" => payment_params, "id" => id}) do
    person = Accounts.get_person!(id)

    case Accounts.create_payment(payment_params, person) do
      {:ok, %{payment: payment, person: person}} ->
        conn
        |> put_flash(:success, "The payment was created successfully.")
        |> redirect(to: Routes.admin_person_path(conn, :show, person))

      {:error, %Ecto.Changeset{} = changeset} ->
        person = Accounts.get_person!(id)

        conn
        |> put_flash(:error, "There was a problem creating the payment.")
        |> render(
          "new.html",
          person: person,
          changeset: changeset
        )
    end
  end
end
