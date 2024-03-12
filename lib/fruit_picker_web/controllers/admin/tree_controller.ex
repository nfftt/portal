defmodule FruitPickerWeb.Admin.TreeController do
  use FruitPickerWeb, :controller

  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.{
    Person,
    Property,
    Tree,
    TreeSnapshot
  }

  def show(conn, %{"user_id" => person_id, "tree_id" => tree_id}) do
    person = Accounts.get_person!(person_id)

    case Accounts.get_my_tree(tree_id, person) do
      {:ok, tree} ->
        render(conn,
          "show.html",
          person: person,
          tree: tree
        )

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.admin_property_path(conn, :show, person))
    end
  end

  def edit(conn, %{"user_id" => person_id, "tree_id" => tree_id}) do
    person = Accounts.get_person!(person_id)

    case Accounts.get_tree(tree_id, person) do
      %Tree{} = tree ->
        if tree.is_active do
          tree_without_snapshots = Accounts.get_my_tree_without_snapshots(tree_id, person)
          changeset = Accounts.change_tree(tree_without_snapshots)
          snapshot_changeset = Accounts.get_tree_snapshot_changelist(tree)
          render(conn,
            "edit.html",
            tree: tree,
            person: person,
            changeset: changeset,
            snapshot_changeset: snapshot_changeset,
            action_name: "Update"
          )
        else
          conn
          |> put_flash(:error, "Sorry, you cannot edit a deactivated tree.")
          |> redirect(to: Routes.admin_property_path(conn, :show, person))
        end

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.admin_property_path(conn, :show, person))
    end
  end

  def update(conn, %{"user_id" => person_id, "tree_id" => tree_id, "tree" => tree_params}) do
    person = Accounts.get_person!(person_id)

    case Accounts.get_tree(tree_id, person) do
      %Tree{} = tree ->
         case Accounts.update_tree(tree, tree_params) do
           {:ok, %{tree: tree}} ->
             conn
             |> put_flash(:success, "Tree updated successfully.")
             |> redirect(to: Routes.admin_tree_path(conn, :show, person, tree))
           {:error, :tree, %Ecto.Changeset{} = changeset, %{}} ->
             render(conn,
               "edit.html",
               tree: tree,
               person: person,
               changeset: changeset,
               snapshot_changeset: %{},
               action_name: "Update"
             )
         end
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.admin_property_path(conn, :show, person))
    end
  end

  def request_deactivate(conn, %{"user_id" => person_id, "tree_id" => tree_id}) do
    person = Accounts.get_person!(person_id)

    case Accounts.get_tree(tree_id, person) do
      %Tree{} = tree ->
        changeset = Tree.deactivate_changeset(tree, %{})
        render(conn,
          "deactivate.html",
          tree: tree,
          person: person,
          changeset: changeset
        )
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.admin_property_path(conn, :show, person))
    end
  end

  def deactivate(conn, %{"user_id" => person_id, "tree_id" => tree_id, "tree" => tree_params}) do
    person = Accounts.get_person!(person_id)

    case Accounts.get_tree(tree_id, person) do
      %Tree{} = tree ->
         case Accounts.deactivate_tree(tree, tree_params) do
           {:ok, tree} ->
             conn
             |> put_flash(:success, "Tree deactivated successfully.")
             |> redirect(to: Routes.admin_tree_path(conn, :show, person, tree))
           {:error, %Ecto.Changeset{} = changeset} ->
             render(conn,
               "deactivate.html",
               tree: tree,
               person: person,
               changeset: changeset
             )
         end
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.admin_property_path(conn, :show, person))
    end
  end
end
