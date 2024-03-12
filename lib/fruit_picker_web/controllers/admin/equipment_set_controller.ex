defmodule FruitPickerWeb.Admin.EquipmentSetController do
  use FruitPickerWeb, :controller

  alias FruitPicker.Inventory
  alias FruitPicker.Inventory.{EquipmentSet}
  alias FruitPicker.Accounts.{Person, Profile}
  alias FruitPickerWeb.{PersonController, Policies}

  plug(Policies, :is_admin)

  def index(conn, params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Inventory.list_equipment_sets(page_num, sort_by, desc)

    render(conn, "index.html",
      page: page,
      equipment_sets: page.entries,
      equipment_sets_count: page.total_entries,
      sort_by: sort_by,
      desc: desc
    )
  end

  def new(conn, _params) do
    changeset = Inventory.change_equipment_set(%EquipmentSet{})
    render(conn, "new.html",
      changeset: changeset,
      action_name: "Add",
    )
  end

  def create(conn, %{"equipment_set" => equipment_set_params}) do
    case Inventory.create_equipment_set(equipment_set_params) do
      {:ok, equipment_set} ->
        conn
        |> put_flash(:success, "The Equipment Set " <> equipment_set.name <> " was created successfully.")
        |> redirect(to: Routes.admin_equipment_set_path(conn, :show, equipment_set))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the set.")
        |> render(
          "new.html",
          changeset: changeset,
          action_name: "Add",
        )
    end
  end

  def show(conn, %{"id" => id}) do
    equipment_set = Inventory.get_equipment_set!(id)
    scheduled_picks = Inventory.get_scheduled_picks(equipment_set)
    completed_picks = Inventory.get_completed_picks(equipment_set)
    render(conn, "show.html",
      equipment_set: equipment_set,
      scheduled_picks: scheduled_picks,
      completed_picks: completed_picks,
    )
  end

  def edit(conn, %{"id" => id}) do
    equipment_set = Inventory.get_equipment_set!(id)
    changeset = Inventory.change_equipment_set(equipment_set)
    render(
      conn,
      "edit.html",
      equipment_set: equipment_set,
      changeset: changeset,
      action_name: "Update",
    )
  end

  def update(conn, %{"id" => id, "equipment_set" => equipment_set_params}) do
    equipment_set = Inventory.get_equipment_set!(id)

    case Inventory.update_equipment_set(equipment_set, equipment_set_params) do
      {:ok, equipment_set} ->
        conn
        |> put_flash(:info, "Equipment Set updated successfully.")
        |> redirect(to: Routes.admin_equipment_set_path(conn, :show, equipment_set))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "edit.html",
          equipment_set: equipment_set,
          changeset: changeset,
          action_name: "Update"
        )
    end
  end

  def activate(conn, %{"id" => id}) do
    equipment_set = Inventory.get_equipment_set!(id)
    {:ok, _equipment_set} = Inventory.activate_equipment_set(equipment_set)

    conn
    |> put_flash(:info, "Equipment Set activated successfully.")
    |> redirect(to: Routes.admin_equipment_set_path(conn, :show, equipment_set))
  end

  def deactivate(conn, %{"id" => id}) do
    equipment_set = Inventory.get_equipment_set!(id)
    {:ok, _equipment_set} = Inventory.deactivate_equipment_set(equipment_set)

    conn
    |> put_flash(:info, "Equipment Set deactivated successfully.")
    |> redirect(to: Routes.admin_equipment_set_path(conn, :show, equipment_set))
  end

  def delete(conn, %{"id" => id}) do
    equipment_set = Inventory.get_equipment_set!(id)
    {:ok, _equipment_set} = Inventory.delete_equipment_set(equipment_set)

    conn
    |> put_flash(:info, "Equipment Set deleted successfully.")
    |> redirect(to: Routes.admin_equipment_set_path(conn, :index))
  end
end
