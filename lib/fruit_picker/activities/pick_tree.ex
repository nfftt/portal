defmodule FruitPicker.Activities.PickTree do
  @moduledoc """
  Data representation of which trees are associated with a pick.
  """

  use FruitPicker.Schema

  alias FruitPicker.Activities.Pick
  alias FruitPicker.Accounts.Tree

  @primary_key false
  schema "picks_trees" do
    belongs_to(:pick, Pick)
    belongs_to(:tree, Tree)
    timestamps()
  end

  @doc false
  def changeset(struct, attrs \\ %{}) do
    struct
    |> Ecto.Changeset.cast(attrs, [:pick_id, :tree_id])
    |> Ecto.Changeset.validate_required([:pick_id, :tree_id])
  end

  def preload_all(pick_tree) do
    pick_tree
    |> preload_pick()
    |> preload_tree()
  end

  def preload_pick(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :pick)
  def preload_pick(pick_tree), do: Repo.preload(pick_tree, :picks)

  def preload_tree(%Ecto.Query{} = query), do: Ecto.Query.preload(query, :tree)
  def preload_tree(pick_tree), do: Repo.preload(pick_tree, :tree)
end
