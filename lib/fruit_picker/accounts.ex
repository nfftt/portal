defmodule FruitPicker.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Argon2, only: [check_pass: 2, no_user_verify: 0]

  alias FruitPicker.{Mailer, Mapbox, Repo}

  alias FruitPicker.Accounts.{
    MembershipPayment,
    PasswordResetToken,
    Person,
    Profile,
    Property,
    Tree,
    TreeSnapshot
  }

  alias FruitPicker.Activities.{
    Pick,
    PickPerson
  }

  alias FruitPickerWeb.{Email, Endpoint}
  alias Phoenix.Token
  alias Ecto.Multi

  # token is valid for 2 hours
  @reset_token_max_age 7_200

  # season cutoff month is March
  @cutoff_month 3

  # season cutoff day is the last day of March
  @cutoff_day 31

  @doc """
  Returns the list of people.

  ## Examples

      iex> list_people()
      [%Person{}, ...]

  """
  # Note the fact that we don't select all columns here may bite us in the ass later
  @person_fields [
    :id,
    :email,
    :first_name,
    :last_name,
    :role,
    :membership_is_active,
    :is_picker,
    :is_lead_picker,
    :is_tree_owner
  ]
  def list_people do
    Person
    |> not_deleted()
    |> select(^@person_fields)
    |> Repo.all()
  end

  def list_people(page) do
    Person
    |> not_deleted()
    |> select(^@person_fields)
    |> Repo.paginate(page: page)
  end

  def list_people(page, sort_by, desc \\ false) do
    Person
    |> not_deleted()
    |> select(^@person_fields)
    |> sort_people_query(sort_by, desc)
    |> Repo.paginate(page: page)
  end

  def list_people_like(search_term) do
    search_term = String.replace(search_term, " ", "")
    search_term = "%#{search_term}%"

    Person
    |> not_deleted()
    |> where([p], ilike(p.email, ^search_term))
    |> or_where(
      [p],
      ilike(fragment("concat(?, ?)", p.first_name, p.last_name), ^search_term) or
        ilike(fragment("concat(?, ?)", p.last_name, p.first_name), ^search_term)
    )
    |> order_by([p], asc: p.last_name, asc: p.first_name, asc: p.email)
    |> select([
      :id,
      :email,
      :first_name,
      :last_name
    ])
    |> Repo.all()
  end

  def list_admins do
    Repo.all(
      from(
        q in not_deleted(Person),
        where: q.role == "admin",
        select: ^@person_fields
      )
    )
  end

  def list_agencies do
    Repo.all(
      from(
        q in not_deleted(Person),
        where: q.role == "agency",
        select: ^@person_fields
      )
    )
  end

  def list_agencies(page, sort_by, desc \\ false) do
    Person
    |> not_deleted()
    |> where([p], p.role == "agency")
    |> select(^@person_fields)
    |> sort_people_query(sort_by, desc)
    |> Repo.paginate(page: page)
  end

  def list_pickers do
    Repo.all(
      from(
        q in not_deleted(Person),
        where: q.is_picker == true,
        select: ^@person_fields
      )
    )
  end

  def list_pickers(page, sort_by, desc \\ false) do
    Person
    |> not_deleted()
    |> where([p], p.is_picker == true)
    |> select(^@person_fields)
    |> sort_people_query(sort_by, desc)
    |> Repo.paginate(page: page)
  end

  def list_available_pickers(pick_id) do
    sub =
      from pp in PickPerson,
        where: pp.pick_id == ^pick_id,
        join: p in Person,
        on: p.id == pp.person_id,
        select: p.id

    ids = Repo.all(sub)

    query =
      from p in not_deleted(Person),
        where: p.is_picker == true,
        where: p.id not in ^ids,
        order_by: [:last_name, :first_name]

    Repo.all(query)
  end

  def list_lead_pickers do
    Repo.all(
      from(
        q in not_deleted(Person),
        where: q.is_lead_picker == true,
        select: ^@person_fields
      )
    )
  end

  def list_sorted_lead_pickers do
    Repo.all(
      from(
        q in not_deleted(Person),
        where: q.is_lead_picker == true,
        order_by: [asc: q.last_name, asc: q.first_name],
        select: ^@person_fields
      )
    )
  end

  def list_lead_pickers(page, sort_by, desc \\ false) do
    Person
    |> not_deleted()
    |> where([lp], lp.is_lead_picker == true)
    |> select(^@person_fields)
    |> sort_people_query(sort_by, desc)
    |> Repo.paginate(page: page)
  end

  def list_tree_owners do
    Repo.all(
      from(
        q in not_deleted(Person),
        where: q.is_tree_owner == true,
        select: ^@person_fields
      )
    )
  end

  def list_tree_owners(page, sort_by, desc) do
    today = Date.utc_today()
    {:ok, year} = NaiveDateTime.new(today.year, 1, 1, 0, 0, 0)

    last_claim =
      from p in Pick,
        group_by: [:requester_id],
        select: %{requester_id: p.requester_id, last_claim: max(p.updated_at)}

    tree_owners =
      from to in not_deleted(Person),
        where: to.is_tree_owner == true,
        left_join: last in subquery(last_claim),
        on: last.requester_id == to.id,
        select: %{to | has_requested_pick_this_year: not is_nil(last) and last.last_claim > ^year}

    tree_owners
    |> sort_people_query(sort_by, desc)
    |> Repo.paginate(page: page)
  end

  def list_tree_owners_with_last_membership_payment do
    membership_paymnet_subquery =
      from(
        mp in MembershipPayment,
        group_by: mp.member_id,
        select: %{
          member_id: mp.member_id,
          start_date: max(mp.start_date),
          end_date: max(mp.end_date)
        }
      )

    Repo.all(
      from(
        p in not_deleted(Person),
        left_join: mp in subquery(membership_paymnet_subquery),
        on: p.id == mp.member_id,
        where: p.is_tree_owner == true,
        select: {struct(p, ^@person_fields), mp.start_date, mp.end_date}
      )
    )
  end

  defp not_deleted(query) do
    query
    |> where([p], p.deleted != true)
  end

  def get_my_property(person),
    do:
      Property
      |> Repo.get_by(person_id: person.id)
      |> Repo.preload(:trees)
      |> Repo.preload(:person)

  def get_my_property!(person),
    do:
      Property
      |> Repo.get_by!(person_id: person.id)
      |> Repo.preload(:trees)
      |> Repo.preload(:person)

  def change_property(%Property{} = property) do
    Property.changeset(property, %{})
  end

  def change_avatar(%Person{} = person) do
    Person.avatar_changeset(person, %{})
  end

  def update_avatar(%Person{} = person, attrs) do
    person
    |> Person.avatar_changeset(attrs)
    |> Repo.update()
  end

  def create_property(attrs \\ %{}, person) do
    %Property{}
    |> Property.changeset(attrs)
    |> check_in_operating_area()
    |> Ecto.Changeset.put_assoc(:person, person)
    |> Repo.insert()
  end

  def update_property(%Property{} = property, attrs) do
    property
    |> Property.changeset(attrs)
    |> check_in_operating_area()
    |> Repo.update()
  end

  def admin_update_property(%Property{} = property, attrs) do
    property
    |> Property.admin_changeset(attrs)
    |> Repo.update()
  end

  def create_payment(attrs \\ %{}, person) do
    payment_changeset =
      %MembershipPayment{}
      |> Ecto.Changeset.change(email: person.email)
      |> MembershipPayment.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:member, person)

    person_changeset = Person.active_membership_changeset(person)

    Multi.new()
    |> Multi.insert(:payment, payment_changeset)
    |> Multi.update(:person, person_changeset)
    |> Repo.transaction()
  end

  def change_tree(%Tree{} = tree) do
    Tree.changeset(tree, %{})
  end

  @spec create_tree(
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any},
          any
        ) :: any
  def create_tree(attrs \\ %{}, property) do
    %Tree{}
    |> Tree.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:property, property)
    |> Repo.insert()
  end

  def get_tree(id, person) do
    tree =
      Tree
      |> Repo.get(id)
      |> Repo.preload([:snapshots, property: :person])
  end

  def get_my_tree(id, current_person) do
    tree =
      Tree
      |> Repo.get!(id)
      |> Repo.preload([:snapshots, property: :person])

    if tree.property.person.id == current_person.id do
      {:ok, tree}
    else
      {:error, "You cannot access a tree that is not your own."}
    end
  end

  def get_my_tree_without_snapshots(id, current_person) do
    query = from(ts in TreeSnapshot, where: [id: 0])

    Tree
    |> Repo.get!(id)
    |> Repo.preload(snapshots: query, property: :person)
  end

  def get_tree_snapshot_changelist(%Tree{} = tree) do
    attrs =
      tree
      |> get_tree_health()
      |> Map.from_struct()

    TreeSnapshot.changeset(%TreeSnapshot{}, attrs)
  end

  def change_tree_snapshot(%TreeSnapshot{} = tree_snapshot, _tree) do
    TreeSnapshot.changeset(tree_snapshot, %{})
  end

  def change_tree_snapshot(nil = tree_snapshot, %Tree{} = tree) do
    attrs = Map.from_struct(tree)
    TreeSnapshot.changeset(%TreeSnapshot{}, attrs)
  end

  defp get_tree_health(%Tree{} = tree) do
    if Enum.any?(tree.snapshots) do
      tree.snapshots
      |> Enum.sort_by(&Map.fetch!(&1, :inserted_at), &>=/2)
      |> Enum.at(0)
    else
      tree
    end
  end

  def get_persons_trees(person_id) when is_binary(person_id) do
    query =
      from(
        p in Property,
        where: p.person_id == ^person_id,
        left_join: t in assoc(p, :trees),
        where: t.property_id == p.id,
        order_by: [desc: p.updated_at],
        select: t
      )

    Repo.all(query)
  end

  def get_persons_trees(person) do
    query =
      from(
        p in Property,
        where: p.person_id == ^person.id,
        left_join: t in assoc(p, :trees),
        where: t.property_id == p.id,
        order_by: [desc: p.updated_at],
        select: t
      )

    Repo.all(query)
  end

  def get_tree!(id), do: Tree |> Repo.get!(id) |> Repo.preload([:snapshots])

  def get_trees(ids) when is_list(ids) do
    # TODO: ensure trees belong to user?
    query = Ecto.Query.from(r in Tree, where: r.id in ^ids)
    Repo.all(query)
  end

  def update_tree(%Tree{} = tree, attrs) do
    %{"snapshots" => %{"0" => snapshot_attrs}} = attrs

    snapshot_changeset =
      %TreeSnapshot{}
      |> TreeSnapshot.changeset(snapshot_attrs)
      |> Ecto.Changeset.put_assoc(:tree, tree)

    tree_changeset = Tree.edit_changeset(tree, attrs)

    Multi.new()
    |> Multi.update(:tree, tree_changeset)
    |> Multi.insert(:snapshot, snapshot_changeset)
    |> Repo.transaction()
  end

  def deactivate_tree(%Tree{} = tree, attrs) do
    tree
    |> Tree.deactivate_changeset(attrs)
    |> Repo.update()
  end

  def create_tree_snapshot(%Tree{} = tree, %Pick{} = pick, attrs) do
    %TreeSnapshot{}
    |> TreeSnapshot.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:tree, tree)
    |> Ecto.Changeset.put_assoc(:pick, pick)
    |> Repo.insert()
  end

  @doc """
  Gets a single person.

  Raises `Ecto.NoResultsError` if the Person does not exist.

  ## Examples

      iex> get_person!(123)
      %Person{}

      iex> get_person!(456)
      ** (Ecto.NoResultsError)

  """
  def get_person!(id), do: Person |> Repo.get!(id) |> Person.preload_all()

  def get_activ_tree_owner(id) do
    Person
    |> where([p], p.id == ^id)
    |> where([p], p.is_tree_owner == true)
    |> where([p], p.membership_is_active == true)
    |> Repo.one()
  end

  def get_profile!(id), do: Repo.get!(Profile, id)

  @doc """
  Creates a person.

  ## Examples

      iex> create_person(%{field: value})
      {:ok, %Person{}}

      iex> create_person(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_person(attrs \\ %{}, account_type) do
    profile_changeset = Profile.changeset(%Profile{}, attrs["profile"])

    %Person{}
    |> Person.register_changeset(attrs, account_type)
    |> handle_account_type(account_type)
    |> Ecto.Changeset.put_assoc(:profile, profile_changeset)
    |> Repo.insert()
  end

  def admin_create_person(attrs \\ %{}, account_type) do
    profile_changeset = Profile.changeset(%Profile{}, attrs["profile"])

    %Person{}
    |> handle_account_type(account_type)
    |> Person.admin_changeset(attrs)
    |> Ecto.Changeset.put_assoc(:profile, profile_changeset)
    |> Repo.insert()
  end

  @doc """
  Updates a person.

  ## Examples

      iex> update_person(person, %{field: new_value})
      {:ok, %Person{}}

      iex> update_person(person, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_person(%Person{} = person, attrs) do
    profile = get_profile!(person.profile.id)
    profile_changeset = Profile.changeset(profile, attrs["profile"])

    person
    |> Person.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:profile, profile_changeset)
    |> Repo.update()
  end

  @doc """
  Soft Deletes a Person.

  ## Examples

      iex> soft_delete_person(person)
      {:ok, %Person{}}

      iex> soft_delete_person(person)
      {:error, %Ecto.Changeset{}}

  """
  def soft_delete_person(%Person{} = person) do
    # Delete the associated profile
    person.profile
    |> Repo.delete()

    # Properties are not deleted for reporting purposes
    person
    |> Person.soft_delete_changeset()
    |> Repo.update()
  end

  def deactivate_person(%Person{} = person) do
    person
    |> Ecto.Changeset.change(membership_is_active: false)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking person changes.

  ## Examples

      iex> change_person(person)
      %Ecto.Changeset{source: %Person{}}

  """
  def change_person(%Person{} = person) do
    Person.changeset(person, %{})
  end

  @doc """
    Creates and sends a one-use token for password reset.
  """
  def provide_password_reset_token(nil), do: {:error, :not_found}

  def provide_password_reset_token(email) when is_binary(email) do
    email =
      email
      |> String.downcase()
      |> String.trim()

    Person
    |> where([p], fragment("lower(?)", p.email) == ^email)
    |> Repo.one()
    |> send_token()
  end

  def provide_password_reset_token(%Person{} = person) do
    send_token(person)
  end

  def create_password(attrs \\ %{}, token_value) do
    with {:ok, person} <- verify_token_value(token_value),
         {:ok, person} <- save_new_password(person, attrs) do
      cleanup_token(person)
      {:ok, person}
    else
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp save_new_password(person, attrs) do
    person
    |> Person.password_changeset(attrs)
    |> Repo.update()
  end

  @doc """
    Checks that the token exists.
  """
  def verify_token_value(value) do
    PasswordResetToken
    |> where([t], t.value == ^value)
    |> where(
      [t],
      t.inserted_at >
        datetime_add(^NaiveDateTime.utc_now(), ^(@reset_token_max_age * -1), "second")
    )
    |> Repo.one()
    |> verify_token()
  end

  @doc """
    Find an existing token.
  """
  def find_token(%Person{} = person) do
    PasswordResetToken
    |> where([prt], prt.person_id == ^person.id)
    |> limit(1)
    |> order_by([prt], desc: prt.inserted_at)
    |> Repo.one()
  end

  def change_profile(%Profile{} = profile) do
    Profile.changeset(profile, %{})
  end

  @doc """
    Check that the token isn't expire and is valid.
  """
  # Unexpired token could not be found.
  defp verify_token(nil), do: {:error, :not_found}

  # Loads the person and deletes the token as it is now used once.
  defp verify_token(token) do
    token =
      token
      |> Repo.preload(:person)

    person_id = token.person.id

    # Verify the token mathces the user id
    case Token.verify(Endpoint, "person", token.value, max_age: @reset_token_max_age) do
      {:ok, ^person_id} ->
        {:ok, token.person}

      # could fail due to :invalid or :expired
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp cleanup_token(person) do
    person
    |> find_token()
    |> Repo.delete()
  end

  def get_person_by_email_and_password(nil, _password), do: {:error, :invalid}
  def get_person_by_email_and_password(_email, nil), do: {:error, :invalid}

  def get_person_by_email_and_password(email, password) do
    email =
      email
      |> String.downcase()
      |> String.trim()

    case Person |> where([p], fragment("lower(?)", p.email) == ^email) |> Repo.one() do
      %Person{} = person ->
        check_pass(person, password)

      _ ->
        # Help to mitigate timing attacks
        no_user_verify()
        {:error, :unauthorised}
    end
  end

  def get_next_season_cutoff_date!(year) do
    {:ok, date} = Date.new(year + 1, @cutoff_month, @cutoff_day)

    date
  end

  def get_next_season_cutoff_date!() do
    year = Date.utc_today().year + 1
    {:ok, date} = Date.new(year, @cutoff_month, @cutoff_day)

    date
  end

  def people_count, do: Repo.aggregate(Person, :count, :id)
  def admin_count, do: Repo.count(from(q in Person, where: q.role == "admin"))
  def agency_count, do: Repo.count(from(q in Person, where: q.role == "agency"))
  def tree_owner_count, do: Repo.count(from(q in Person, where: q.is_tree_owner == true))
  def picker_count, do: Repo.count(from(q in Person, where: q.is_picker == true))
  def lead_picker_count, do: Repo.count(from(q in Person, where: q.is_lead_picker == true))

  # Person could not be found by email
  defp send_token(nil), do: {:error, :not_found}

  # Send a token to the user by email.
  defp send_token(person) do
    person
    |> create_token()
    |> Email.password_reset(person)
    |> Mailer.deliver_later()
  end

  defp create_token(person) do
    changeset = PasswordResetToken.changeset(%PasswordResetToken{}, person)
    token = Repo.insert!(changeset)
    token.value
  end

  defp handle_account_type(person, account_type) do
    case account_type do
      "fruit_picker" ->
        Ecto.Changeset.change(person, is_picker: true)

      "lead_fruit_picker" ->
        Ecto.Changeset.change(person, is_lead_picker: true)

      "tree_owner" ->
        Ecto.Changeset.change(person, is_tree_owner: true)

      "agency" ->
        Ecto.Changeset.change(person, role: :agency)

      "admin" ->
        Ecto.Changeset.change(person, role: :admin)

      _ ->
        person
    end
  end

  defp check_in_operating_area(changeset) do
    address_postal_code = Ecto.Changeset.get_field(changeset, :address_postal_code)

    if Mapbox.check_in_bounds(address_postal_code) do
      Ecto.Changeset.change(changeset, is_in_operating_area: true)
    else
      Ecto.Changeset.change(changeset, is_in_operating_area: false)
    end
  end

  defp sort_people_query(query, field, desc) do
    cond do
      field not in [
        "first_name",
        "last_name",
        "role",
        "membership_is_active"
      ] ->
        query

      desc == "true" ->
        order_by(query, desc: ^String.to_existing_atom(field))

      true ->
        order_by(query, asc: ^String.to_existing_atom(field))
    end
  end
end
