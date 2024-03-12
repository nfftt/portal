defmodule FruitPickerWeb.TreeController do
  use FruitPickerWeb, :controller

  alias FruitPicker.Mailchimp
  alias FruitPicker.Accounts

  alias FruitPicker.Accounts.{
    Person,
    Property,
    Tree,
    TreeSnapshot
  }

  alias FruitPickerWeb.Policies

  def new(conn, _params) do
    changeset = Tree.changeset(%Tree{}, %{})

    render(
      conn,
      "new.html",
      changeset: changeset
    )
  end

  def create(conn, %{"tree" => tree_params}) do
    property = Accounts.get_my_property(conn.assigns.current_person)

    case Accounts.create_tree(tree_params, property) do
      {:ok, tree} ->
        me = conn.assigns.current_person

        Task.start(fn ->
          Mailchimp.add_fruit_tag_to_tree_owner(me.email, tree.type)
        end)

        conn
        |> put_flash(
          :success,
          "The tree was created successfully. If you've added all of your trees, you can create a pick request from the dashboard."
        )
        |> redirect(to: Routes.tree_path(conn, :show, tree))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the tree.")
        |> render(
          "new.html",
          changeset: changeset,
          action_name: "Add"
        )
    end
  end

  def show(conn, %{"id" => id}) do
    case Accounts.get_my_tree(id, conn.assigns.current_person) do
      {:ok, tree} ->
        render(
          conn,
          "show.html",
          tree: tree
        )

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.property_path(conn, :index))
    end
  end

  def edit(conn, %{"id" => id}) do
    case Accounts.get_my_tree(id, conn.assigns.current_person) do
      {:ok, tree} ->
        if tree.is_active do
          tree_without_snapshots =
            Accounts.get_my_tree_without_snapshots(id, conn.assigns.current_person)

          changeset = Accounts.change_tree(tree_without_snapshots)
          snapshot_changeset = Accounts.get_tree_snapshot_changelist(tree)

          render(
            conn,
            "edit.html",
            tree: tree,
            changeset: changeset,
            snapshot_changeset: snapshot_changeset,
            action_name: "Update"
          )
        else
          conn
          |> put_flash(:error, "Sorry, you cannot edit a deactivated tree.")
          |> redirect(to: Routes.property_path(conn, :index))
        end

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.property_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "tree" => tree_params}) do
    case Accounts.get_my_tree(id, conn.assigns.current_person) do
      {:ok, tree} ->
        case Accounts.update_tree(tree, tree_params) do
          {:ok, %{tree: tree}} ->
            conn
            |> put_flash(:success, "Tree updated successfully.")
            |> redirect(to: Routes.tree_path(conn, :show, tree))

          {:error, :tree, %Ecto.Changeset{} = changeset, %{}} ->
            render(
              conn,
              "edit.html",
              tree: tree,
              changeset: changeset,
              snapshot_changeset: %{},
              action_name: "Update"
            )
        end

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.property_path(conn, :index))
    end
  end

  def request_deactivate(conn, %{"id" => id}) do
    case Accounts.get_my_tree(id, conn.assigns.current_person) do
      {:ok, tree} ->
        changeset = Tree.deactivate_changeset(tree, %{})

        render(
          conn,
          "deactivate.html",
          tree: tree,
          changeset: changeset
        )

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.property_path(conn, :index))
    end
  end

  def deactivate(conn, %{"id" => id, "tree" => tree_params}) do
    case Accounts.get_my_tree(id, conn.assigns.current_person) do
      {:ok, tree} ->
        case Accounts.deactivate_tree(tree, tree_params) do
          {:ok, tree} ->
            conn
            |> put_flash(:success, "Tree deactivated successfully.")
            |> redirect(to: Routes.tree_path(conn, :show, tree))

          {:error, %Ecto.Changeset{} = changeset} ->
            render(
              conn,
              "deactivate.html",
              tree: tree,
              changeset: changeset
            )
        end

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.property_path(conn, :index))
    end
  end
end
