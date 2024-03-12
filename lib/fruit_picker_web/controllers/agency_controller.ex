defmodule FruitPickerWeb.AgencyController do
  use FruitPickerWeb, :controller

  alias FruitPicker.Partners
  alias FruitPicker.Partners.{Agency}
  alias FruitPicker.Accounts.{Person, Profile}
  alias FruitPickerWeb.{PersonController, Policies}

  plug(Policies, :is_agency when action in [:mine, :new, :edit, :udpate])
  plug(Policies, :is_lead_picker when action in [:index, :show])

  def index(conn, params) do
    page_num = Map.get(params, "page", "1")
    page = Partners.list_agencies(page_num)

    render(conn, "index.html",
      page: page,
      agencies: page.entries,
      agencies_count: page.total_entries,
    )
  end

  def new(conn, _params) do
    changeset = Partners.change_agency(%Agency{})
    render(conn, "new.html",
      changeset: changeset,
      action_name: "Add",
    )
  end

  def create(conn, %{"agency" => agency_params}) do
    partner_id = conn.assigns.current_person.id
    params = Map.put(agency_params, "partner_id", partner_id)

    case Partners.create_agency(params) do
      {:ok, agency} ->
        conn
        |> put_flash(:success, "The Agency " <> agency.name <> " was successfully setup.")
        |> redirect(to: Routes.agency_path(conn, :mine))
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the agency.")
        |> render(
          "new.html",
          changeset: changeset,
          action_name: "Add",
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
      completed_picks: completed_picks,
    )
  end

  def mine(conn, _params) do
    agency = Partners.get_my_agency!(conn.assigns.current_person)

    if agency do
      scheduled_picks = Partners.get_scheduled_picks(agency)
      completed_picks = Partners.get_completed_picks(agency)

      render(conn, "show.html",
        agency: agency,
        scheduled_picks: scheduled_picks,
        completed_picks: completed_picks,
      )
    else
      redirect(conn, to: Routes.agency_path(conn, :new))
    end
  end

  def edit(conn, _params) do
    agency = Partners.get_my_agency!(conn.assigns.current_person)

    if agency do
      changeset = Partners.change_agency(agency)
      render(
        conn,
        "edit.html",
        agency: agency,
        changeset: changeset,
        action_name: "Update",
      )
    else
      redirect(conn, to: Routes.agency_path(conn, :new))
    end
  end

  def update(conn, %{"agency" => agency_params}) do
    agency = Partners.get_my_agency!(conn.assigns.current_person)

    case Partners.update_agency(agency, agency_params) do
      {:ok, agency} ->
        conn
        |> put_flash(:info, "Agency updated successfully.")
        |> redirect(to: Routes.agency_path(conn, :mine))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(
          conn,
          "edit.html",
          agency: agency,
          changeset: changeset,
          action_name: "Update"
        )
    end
  end
end
