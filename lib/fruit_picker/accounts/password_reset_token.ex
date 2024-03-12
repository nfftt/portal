defmodule FruitPicker.Accounts.PasswordResetToken do
  @moduledoc """
  Data representation of one-time use tokens for temp
  authentication to reset a password.
  """

  use FruitPicker.Schema

  alias FruitPicker.Accounts.Person
  alias FruitPickerWeb.Endpoint
  alias Phoenix.Token

  schema "password_reset_tokens" do
    field(:value, :string)
    belongs_to(:person, Person)

    timestamps(updated_at: false)
  end

  def changeset(token, person) do
    token
    |> cast(%{}, [])
    |> put_assoc(:person, person)
    |> put_change(:value, generate_token(person))
    |> validate_required([:value, :person])
    |> unique_constraint(:value)
  end

  defp generate_token(nil), do: nil

  defp generate_token(person) do
    Token.sign(Endpoint, "person", person.id)
  end
end
