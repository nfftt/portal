defmodule FruitPickerWeb.StatsController do
  use FruitPickerWeb, :controller

  import Ecto.Query, warn: false

  alias FruitPicker.Accounts.Person
  alias FruitPicker.Activities.PickAttendance
  alias FruitPicker.Stats
  alias FruitPicker.Repo

  def index(conn, _params) do
    me = conn.assigns.current_person

    case stats_type(me) do
      :admin ->
        admin_stats(conn)
      :tree_owner ->
        tree_owner_stats(conn)
      :lead_picker ->
        lead_picker_stats(conn)
      :picker ->
        picker_stats(conn)
      :blank ->
        blank_stats(conn)
    end
  end

  defp admin_stats(conn) do
    me = conn.assigns.current_person
    missed_picks_count = Stats.get_missed_picks_count(me)
    season_stats = Stats.lead_picker_season_stats(me)
    total_stats = Stats.lead_picker_total_stats(me)

    render(conn, "lead_picker.html",
      season_stats: season_stats,
      total_stats: total_stats,
      missed_picks_count: missed_picks_count
    )
  end

  defp tree_owner_stats(conn) do
    me = conn.assigns.current_person
    season_stats = Stats.tree_owner_season_stats(me)
    total_stats = Stats.tree_owner_total_stats(me)

    render(conn, "tree_owner.html",
      season_stats: season_stats,
      total_stats: total_stats,
    )
  end

  defp lead_picker_stats(conn) do
    me = conn.assigns.current_person
    missed_picks_count = Stats.get_missed_picks_count(me)
    season_stats = Stats.lead_picker_season_stats(me)
    total_stats = Stats.lead_picker_total_stats(me)

    render(conn, "lead_picker.html",
      season_stats: season_stats,
      total_stats: total_stats,
      missed_picks_count: missed_picks_count
    )
  end

  defp picker_stats(conn) do
    me = conn.assigns.current_person
    missed_picks_count = Stats.get_missed_picks_count(me)
    season_stats = Stats.picker_season_stats(me)
    total_stats = Stats.picker_total_stats(me)

    render(conn, "picker.html",
      season_stats: season_stats,
      total_stats: total_stats,
      missed_picks_count: missed_picks_count
    )
  end

  defp blank_stats(conn) do
    me = conn.assigns.current_person
    missed_picks_count = Stats.get_missed_picks_count(me)

    render(conn, "picker.html",
      season_stats: %{},
      total_stats: %{},
      missed_picks_count: missed_picks_count
    )
  end

  defp stats_type(%Person{} = person) do
    cond do
      person.role == :admin ->
        :admin
      person.role == :user and person.is_tree_owner ->
        :tree_owner
      person.role == :user and person.is_lead_picker ->
        :lead_picker
      person.role == :user and person.is_picker ->
        :picker
      true ->
        :blank
    end
  end
end
