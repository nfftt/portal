defmodule FruitPickerWeb.Admin.RequestPickView do
  use FruitPickerWeb, :view

  alias FruitPickerWeb.SharedView
  alias FruitPickerWeb.TreeView
  alias FruitPicker.Accounts.Tree
  alias FruitPicker.Activities.Pick

  def tree_hover_classes(%Tree{} = tree) do
    if tree.is_active, do: "tree-block-hover pointer"
  end

  def tree_hover_classes(tree) do
    ""
  end

  def tree_checked?(%Pick{} = pick, tree) do
    Enum.any?(pick.trees, fn t -> t.id == tree.id end)
  end

  def tree_checked?(%Ecto.Changeset{} = changeset, tree) do
    cond do
      changeset.changes[:trees] ->
        Enum.any?(changeset.changes.trees, fn t -> t.id == tree.id end)

      changeset.data.trees ->
        Enum.any?(changeset.data.trees, fn t -> t.id == tree.id end)

      true ->
        false
    end
  end
end
