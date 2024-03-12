defmodule FruitPickerWeb.Admin.AgencyController do
  use FruitPickerWeb, :controller

  alias FruitPicker.Partners
  alias FruitPicker.Partners.{Agency}
  alias FruitPickerWeb.Policies

  plug(Policies, :is_admin)

  def index(conn, params) do
    page_num = Map.get(params, "page", "1")
    sort_by = Map.get(params, "sort_by")
    desc = Map.get(params, "desc")
    page = Partners.list_agencies(page_num, sort_by, desc)

    render(conn, "index.html",
      page: page,
      agencies: page.entries,
      agencies_count: page.total_entries,
      sort_by: sort_by,
      desc: desc
    )
  end

  def new(conn, _params) do
    changeset = Partners.change_agency(%Agency{})
    available_people = available_with_current(nil)

    render(conn, "new.html",
      changeset: changeset,
      available_people: available_people,
      action_name: "Add"
    )
  end

  def create(conn, %{"agency" => agency_params}) do
    case Partners.create_agency(agency_params) do
      {:ok, agency} ->
        conn
        |> put_flash(:success, "The Agency " <> agency.name <> " was created successfully.")
        |> redirect(to: Routes.admin_agency_path(conn, :show, agency))

      {:error, %Ecto.Changeset{} = changeset} ->
        available_people = available_with_current(nil)

        conn
        |> put_flash(:error, "There was a problem creating the agency.")
        |> render(
          "new.html",
          changeset: changeset,
          available_people: available_people,
          action_name: "Add"
        )
    end
  end

  def show(conn, %{"id" => id}) do
    agency = Partners.get_agency!(id)
    scheduled_picks = Partners.get_scheduled_picks(agency)
    completed_picks = Partners.get_completed_picks(agency)

    render(conn, "show.html",
      agency: agency,
      scheduled_picks: scheduled_picks,
      completed_picks: completed_picks
    )
  end

  def edit(conn, %{"id" => id}) do
    agency = Partners.get_agency!(id)
    current_partner = agency.partner
    available_people = available_with_current(current_partner)
    changeset = Partners.change_agency(agency)

    render(
      conn,
      "edit.html",
      agency: agency,
      available_people: available_people,
      changeset: changeset,
      action_name: "Update"
    )
  end

  def update(conn, %{"id" => id, "agency" => agency_params}) do
    agency = Partners.get_agency!(id)
    current_partner = agency.partner

    case Partners.update_agency(agency, agency_params) do
      {:ok, agency} ->
        conn
        |> put_flash(:info, "Agency updated successfully.")
        |> redirect(to: Routes.admin_agency_path(conn, :show, agency))

      {:error, %Ecto.Changeset{} = changeset} ->
        available_people = available_with_current(current_partner)

        render(
          conn,
          "edit.html",
          agency: agency,
          available_people: available_people,
          changeset: changeset,
          action_name: "Update"
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    agency = Partners.get_agency!(id)
    {:ok, _agency} = Partners.delete_agency(agency)

    conn
    |> put_flash(:info, "Agency deleted successfully.")
    |> redirect(to: Routes.admin_agency_path(conn, :index))
  end

  @export_fields [
    :name,
    :address,
    :closest_intersection,
    :latitude,
    :longitude,
    :contact_name,
    :contact_email,
    :contact_number,
    :secondary_contact_name,
    :secondary_contact_email,
    :secondary_contact_number,
    :is_accepting_fruit,
    :special_instructions,

    # wanted fruit
    :accepting_sweet_cherries,
    :accepting_sour_cherries,
    :accepting_serviceberries,
    :accepting_mulberries,
    :accepting_apricots,
    :accepting_crabapples,
    :accepting_plums,
    :accepting_apples,
    :accepting_pears,
    :accepting_grapes,
    :accepting_elderberries,
    :accepting_gingko,
    :accepting_black_walnuts,
    :accepting_quince,
    :accepting_pawpaw,

    # scheduling fields
    :sunday_hours_start,
    :sunday_hours_end,
    :sunday_closed,
    :monday_hours_start,
    :monday_hours_end,
    :monday_closed,
    :tuesday_hours_start,
    :tuesday_hours_end,
    :tuesday_closed,
    :wednesday_hours_start,
    :wednesday_hours_end,
    :wednesday_closed,
    :thursday_hours_start,
    :thursday_hours_end,
    :thursday_closed,
    :friday_hours_start,
    :friday_hours_end,
    :friday_closed,
    :saturday_hours_start,
    :saturday_hours_end,
    :saturday_closed,
    :coordinates_updated_at,
    :inserted_at,
    :updated_at
  ]
  def export(conn, _params) do
    agencies = Partners.list_all_agencies()

    parse_row = fn row -> Enum.map(@export_fields, &Map.get(row, &1)) end

    rows =
      agencies
      |> Enum.map(parse_row)

    csv_data =
      ([@export_fields] ++ rows)
      |> CSV.encode()
      |> Enum.to_list()
      |> to_string()

    conn
    |> put_resp_header("content-disposition", "attachment;filename=agencies.csv")
    |> put_resp_content_type("text/csv")
    |> send_resp(200, csv_data)
  end

  def available_with_current(person) do
    if person do
      [person | Partners.get_available()]
    else
      Partners.get_available()
    end
  end
end
