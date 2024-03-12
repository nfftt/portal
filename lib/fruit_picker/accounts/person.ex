defmodule FruitPicker.Accounts.Person do
  @moduledoc """
  Data representation of users/people.
  """

  use FruitPicker.Schema

  import Argon2, only: [add_hash: 1]

  alias FruitPicker.Accounts.{
    Avatar,
    Person,
    Profile,
    Property
  }

  alias FruitPicker.Partners.Agency

  defenum(RoleEnum, :role, [:user, :agency, :admin])

  schema "people" do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)
    field(:role, RoleEnum)
    field(:is_picker, :boolean)
    field(:is_lead_picker, :boolean)
    field(:is_tree_owner, :boolean)
    field(:avatar, Avatar.Type)
    field(:has_requested_pick_this_year, :boolean, virtual: true)

    field(:accepts_portal_communications, :boolean, default: true)
    field(:accepts_consent_picker, :boolean, default: false)
    field(:accepts_consent_tree_owner, :boolean, default: false)
    field(:membership_is_active, :boolean, default: false)
    field(:number_picks_trigger_waitlist, :integer) #the default is 5

    has_one(:profile, Profile, on_delete: :delete_all)
    has_one(:property, Property)
    has_one(:agency, Agency)

    timestamps()
  end

  def is_admin(%Person{} = person), do: person.role == :admin
  def is_agency(%Person{} = person), do: person.role == :agency
  def not_agency(%Person{} = person), do: person.role != :agency
  def is_user(%Person{} = person), do: person.role == :user

  @doc false
  def avatar_changeset(person, attrs) do
    person
    |> cast_attachments(attrs, [:avatar])
    |> validate_required([:avatar])
  end

  @doc false
  def register_changeset(person, attrs, account_type) do
    attrs = lowercase_email(attrs)

    person
    |> cast(attrs, [
      :email,
      :role,
      :first_name,
      :last_name,
      :password,
      :password_confirmation,
      :is_picker,
      :is_lead_picker,
      :is_tree_owner,
      :accepts_portal_communications,
      :accepts_consent_picker,
      :accepts_consent_tree_owner
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :email,
      :password,
      :password_confirmation,
      :accepts_portal_communications
    ])
    |> validate_length(:password, min: 8, max: 80)
    |> validate_confirmation(:password)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,63}$/)
    |> validate_consent(account_type)
    |> unique_constraint(:email)
    |> foreign_key_constraint(:profile_id)
    |> put_pass_hash()
  end

  @doc false
  def changeset(person, attrs) do
    attrs = lowercase_email(attrs)

    person
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :role,
      :is_picker,
      :is_lead_picker,
      :is_tree_owner,
      :password,
      :password_confirmation,
      :accepts_portal_communications,
      :accepts_consent_picker,
      :accepts_consent_tree_owner,
      :membership_is_active,
      :number_picks_trigger_waitlist
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :email,
      :role,
      :is_picker,
      :is_lead_picker,
      :is_tree_owner
    ])
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password)
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  @doc false
  def admin_changeset(person, attrs) do
    attrs = lowercase_email(attrs)

    person
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :role,
      :is_picker,
      :is_lead_picker,
      :is_tree_owner,
      :password,
      :password_confirmation,
      :membership_is_active,
      :number_picks_trigger_waitlist
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :email
    ])
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password)
    |> unique_constraint(:email)
    |> foreign_key_constraint(:profile_id)
    |> put_pass_hash()
  end

  @doc false
  def signin_changeset(person, attrs) do
    attrs = lowercase_email(attrs)

    person
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> put_pass_hash()
  end

  @doc false
  def password_changeset(person, attrs) do
    person
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 8, max: 80)
    |> validate_confirmation(:password)
    |> put_pass_hash()
  end

  @doc false
  def active_membership_changeset(%Person{} = person) do
    change(person, membership_is_active: true)
  end

  @doc false
  def inactive_membership_changeset(%Person{} = person) do
    change(person, membership_is_active: false)
  end

  @doc false
  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: pass}} = changeset) do
    change(changeset, add_hash(pass))
  end

  @doc false
  defp put_pass_hash(changeset), do: changeset

  def preload_all(person) do
    person
    |> preload_profile()
    |> preload_property()
  end

  def preload_profile(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :profile)
  def preload_profile(person), do: Repo.preload(person, :profile)

  def preload_property(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :property)
  def preload_property(person), do: Repo.preload(person, :property)

  def admins, do: from(p in Person, where: p.role == ^:admin)
  def admins(query \\ __MODULE__), do: from(q in query, where: q.role == ^:admin)

  def lead_pickers, do: from(p in Person, where: p.is_lead_picker == true)
  def lead_pickers(query \\ __MODULE__), do: from(q in query, where: q.is_lead_picker == true)

  def active, do: from(p in Person, where: p.is_active == true)
  def active(query \\ __MODULE__), do: from(q in query, where: q.is_active == true)

  defp validate_consent(changeset, account_type) do
    cond do
      account_type == "tree_owner" && get_field(changeset, :accepts_consent_tree_owner) == false ->
        add_error(
          changeset,
          :accepts_consent_tree_owner,
          "You must consent to the waiver to continue"
        )

      account_type == "fruit_picker" && get_field(changeset, :accepts_consent_picker) == false ->
        add_error(
          changeset,
          :accepts_consent_fruit_picker,
          "You must consent to the waiver to continue"
        )

      true ->
        changeset
    end
  end

  defp lowercase_email(attrs) do
    email = Map.get(attrs, "email")

    if is_nil(email) do
      attrs
    else
      Map.put(attrs, "email", String.downcase(email))
    end
  end
end
