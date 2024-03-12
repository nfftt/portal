defmodule FruitPicker.Inventory do
  @moduledoc """
  The Inventory context.
  """

  import Ecto.Query, warn: false

  alias FruitPicker.Repo
  alias FruitPicker.Inventory.EquipmentSet

  alias FruitPicker.Activities.{
    Pick,
    PickFruit
  }

  def list_equipment_sets do
    EquipmentSet
    |> select([
      :id,
      :name,
      :address,
      :closest_intersection,
      :contact_name,
      :contact_number
    ])
    |> Repo.all()
  end

  def list_equipment_sets(:active) do
    EquipmentSet
    |> select([
      :id,
      :name,
      :address,
      :closest_intersection,
      :contact_name,
      :contact_number
    ])
    |> EquipmentSet.active()
    |> Repo.all()
  end

  def list_equipment_sets_available(date, start_time) do
    date = Date.from_iso8601!(date)
    start_time = Time.from_iso8601!(start_time)
    end_time = Time.add(start_time, 7200, :second)

    ids =
      Pick
      |> where([p], p.scheduled_date == ^date)
      |> where([p], p.scheduled_start_time < ^Time.add(end_time, 3600, :second))
      |> where([p], p.scheduled_end_time > ^Time.add(start_time, -3600, :second))
      |> select([p], p.equipment_set_id)
      |> Repo.all()

    EquipmentSet
    |> where([e], not (e.id in ^ids))
    |> Repo.all()
  end

  def list_equipment_sets(page) do
    EquipmentSet
    |> select([
      :id,
      :name,
      :address,
      :closest_intersection,
      :contact_name,
      :contact_number
    ])
    |> Repo.paginate(page: page)
  end

  def list_equipment_sets(page, sort_by, desc \\ false) do
    EquipmentSet
    |> select([
      :id,
      :name,
      :address,
      :closest_intersection,
      :contact_name,
      :contact_number
    ])
    |> sort_equipment_query(sort_by, desc)
    |> Repo.paginate(page: page)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking equipment set changes.

  """
  def change_equipment_set(%EquipmentSet{} = equipment_set) do
    EquipmentSet.changeset(equipment_set, %{})
  end

  def create_equipment_set(attrs \\ %{}) do
    %EquipmentSet{}
    |> EquipmentSet.changeset(attrs)
    |> Repo.insert()
  end

  def get_equipment_set!(id), do: Repo.get!(EquipmentSet, id)

  def update_equipment_set(%EquipmentSet{} = equipment_set, attrs) do
    equipment_set
    |> EquipmentSet.changeset(attrs)
    |> Repo.update()
  end

  def activate_equipment_set(%EquipmentSet{} = equipment_set) do
    equipment_set
    |> EquipmentSet.activation_changeset(%{is_active: true})
    |> Repo.update()
  end

  def deactivate_equipment_set(%EquipmentSet{} = equipment_set) do
    equipment_set
    |> EquipmentSet.activation_changeset(%{is_active: false})
    |> Repo.update()
  end

  def delete_equipment_set(%EquipmentSet{} = equipment_set) do
    Repo.delete(equipment_set)
  end

  def get_scheduled_picks(%EquipmentSet{} = equipment_set) do
    Pick
    |> where(equipment_set_id: ^equipment_set.id)
    |> where([p], p.status in [^:claimed])
    |> Pick.preload_trees()
    |> Repo.all()
  end

  def get_completed_picks(%EquipmentSet{} = equipment_set) do
    Pick
    |> where(equipment_set_id: ^equipment_set.id)
    |> where(status: ^:completed)
    |> join(:inner, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> group_by([pick, fruit], [pick.id])
    |> Pick.preload_trees()
    |> order_by([pick], desc: pick.scheduled_date)
    |> select([pick, fruit], %{
      pick: pick,
      pounds_picked: sum(fruit.total_pounds_picked),
      pounds_donated: sum(fruit.total_pounds_donated)
    })
    |> Repo.all()
  end

  defp sort_equipment_query(query, field, desc) do
    cond do
      field not in [
        "name",
        "address",
        "closest_intersection",
        "contact_name"
      ] ->
        query

      desc == "true" ->
        order_by(query, desc: ^String.to_existing_atom(field))

      true ->
        order_by(query, asc: ^String.to_existing_atom(field))
    end
  end
end
