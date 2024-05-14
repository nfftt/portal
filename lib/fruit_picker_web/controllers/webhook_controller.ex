defmodule FruitPickerWeb.WebhookController do
  use FruitPickerWeb, :controller

  alias FruitPicker.{Mailer, Repo}
  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.{Person, MembershipPayment}
  alias FruitPickerWeb.Email
  alias Ecto.Multi

  import Logger

  def create(conn, _params) do
    handle_webhook(conn)
  end

  defp handle_webhook(conn) do
    payload = conn.assigns.raw_body
    secret = Application.get_env(:fruit_picker, :stripe_webhook_secret)

    signature =
      conn
      |> Plug.Conn.get_req_header("stripe-signature")
      |> Enum.at(0)

    case Stripe.Webhook.construct_event(payload, signature, secret) do
      {:ok, %Stripe.Event{} = event} ->
        case event.type do
          "checkout.session.completed" ->
            handle_success(conn, payload)

          _ ->
            handle_error(conn, "Webhook of type #{event.type} received and ignored.")
        end

      {:error, reason} ->
        handle_error(conn, reason)
    end
  end

  defp update_member(nil, attrs) do
    {:error, "Could not a fetch a user due to 'nil' email address"}
  end

  defp update_member(email, attrs) do
    case Repo.get_by(Person, email: email) do
      %Person{} = person ->
        member_changeset = Person.active_membership_changeset(person)

        payment_changeset =
          MembershipPayment.changeset(
            %MembershipPayment{},
            Map.put(attrs, "member_id", person.id)
          )

        Multi.new()
        |> Multi.insert(:payment, payment_changeset)
        |> Multi.update(:member, member_changeset)
        |> Repo.transaction()

      nil ->
        {:ok, "Skipping webhook, there is no user with the email address #{email}"}
    end
  end

  defp handle_success(conn, payload) do
    %{"data" => event_data} =
      payload
      |> Stripe.API.json_library().decode!()

    Logger.info("Stripe payload: #{inspect(event_data)}")

    email = get_in(event_data, ["object", "customer_details", "email"])
    amount_in_cents = get_in(event_data, ["object", "amount_total"])
    type = payment_type(amount_in_cents)

    attrs = %{
      "email" => email,
      "type" => type,
      "amount_in_cents" => amount_in_cents,
      "start_date" => Date.utc_today(),
      "end_date" => Accounts.get_next_season_cutoff_date!()
    }

    case update_member(email, attrs) do
      {:ok, %{member: member, payment: _payment}} ->
        Logger.info("The membership status for #{email} has been successfully updated to active.")

        if member.is_picker do
          Logger.info(
            "Sending welcome email to fruit picker #{member.first_name} #{member.last_name} (#{
              email
            })."
          )

          member
          |> Email.fruit_picker_payment_email()
          |> Mailer.deliver_later()
        end

        if member.is_tree_owner do
          Logger.info(
            "Sending welcome email to tree owner #{member.first_name} #{member.last_name} (#{
              email
            })."
          )

          member
          |> Email.tree_owner_payment_email()
          |> Mailer.deliver_later()
        end

        conn |> send_resp(201, "")

      {:ok, message} ->
        Logger.info(message)
        send_resp(conn, 201, "")

      {:error, :payment, _reason} ->
        handle_error(
          conn,
          "There was a problem trying to update the member status for #{email} due to the payment details."
        )

      {:error, :person, _reason} ->
        handle_error(
          conn,
          "There was a problem trying to update the member status for #{email} due to the member details."
        )

      {:error, reason} ->
        handle_error(
          conn,
          "There was a problem trying to update the member status for #{email}. #{reason}"
        )
    end
  end

  defp handle_error(conn, message) do
    Logger.error(message)
    conn |> send_resp(400, "")
  end

  defp payment_type(1000), do: "Fruit Picker Membership"
  defp payment_type(4000), do: "Tree Owner Membership"
  defp payment_type(_), do: "Donation"
end
