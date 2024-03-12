defmodule FruitPickerWeb.Admin.RequestPickController do
  use FruitPickerWeb, :controller

  alias FruitPicker.Accounts
  alias FruitPicker.Activities
  alias FruitPicker.Activities.Pick

  def new(conn, %{"id" => id}) do
    trees = Accounts.get_persons_trees(id)
    person = Accounts.get_person!(id)

    changeset = Activities.change_pick(%Pick{})

    if length(trees) > 0 and person.membership_is_active do
      render(conn, "index.html",
        changeset: changeset,
        trees: trees,
        action: "#",
        id: id,
        person: person
      )
    else
      conn
      |> put_flash(
        :error,
        "Tree owners must have at least one tree to request a pick. Please add a tree to your property first."
      )
      |> redirect(to: Routes.admin_person_path(conn, :show, id))
    end
  end

  def create(conn, %{"id" => id, "pick" => pick_params}) do
    trees = fetch_trees(pick_params)
    person = Accounts.get_person!(id)
    my_trees = Accounts.get_persons_trees(person)

    case Activities.admin_create_pick(pick_params, person, trees) do
      {:ok, pick} ->
        conn
        |> put_flash(:info, "Requested a pick.")
        |> redirect(to: Routes.admin_pick_path(conn, :show, pick.id))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem requesting the pick.")
        |> render("new.html",
          changeset: changeset,
          trees: my_trees
        )

      {:error, _} ->
        conn
        |> put_flash(:error, "There was a problem requesting the pick.")
        |> render("new.html",
          trees: my_trees
        )
    end
  end

  defp fetch_trees(pick_params) do
    if Map.has_key?(pick_params, "tree_ids") do
      pick_params["tree_ids"]
      |> Map.keys()
      |> Accounts.get_trees()
    else
      []
    end
  end
end
