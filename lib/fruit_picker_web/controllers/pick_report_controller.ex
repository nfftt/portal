defmodule FruitPickerWeb.PickReportController do
  @moduledoc false

  use FruitPickerWeb, :controller

  alias FruitPicker.Accounts

  alias FruitPicker.Accounts.{
    Person,
    Tree,
    TreeSnapshot
  }

  alias FruitPicker.Activities

  import Ecto.Changeset

  alias FruitPicker.Activities.{
    Pick,
    PickAttendance,
    PickFruit,
    PickReport,
    PickFruitAgency
  }

  alias FruitPicker.{
    Inventory,
    Repo,
    Partners,
    Mailer
  }

  alias FruitPickerWeb.{Email, Resources}
  alias Ecto.Multi
  alias Ecto.Changeset

  def new(conn, %{"pick_id" => pick_id}) do
    me = conn.assigns.current_person
    pick = Activities.get_pick!(pick_id)
    changeset = PickReport.changeset(%PickReport{}, %{})

    cond do
      is_map(pick.report) and pick.report.is_complete ->
        conn
        |> put_flash(:error, "This pick already has a completed report.")
        |> redirect(to: pick_path(conn, me, pick))

      is_map(pick.report) ->
        conn
        |> redirect(to: Routes.pick_report_path(conn, :fruit, pick))

      is_nil(pick.lead_picker) ->
        conn
        |> put_flash(:error, "You don't have permission to create this report")
        |> redirect(to: pick_path(conn, me, pick))

     can_edit?(pick, me) ->
        render(conn, "new.html",
          pick: pick,
          changeset: changeset
        )

      true ->
        conn
        |> put_flash(:error, "You don't have permission to create this report")
        |> redirect(to: pick_path(conn, me, pick))
    end
  end

  def create(conn, %{"pick_report" => report_params, "pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)

    me = conn.assigns.current_person
    attendees = Map.get(report_params, "attendees") || [] |> Enum.to_list()

    if can_edit?(pick, me) do
      case Activities.create_report(report_params, pick, me, attendees) do
        {:ok, %{pick_report: report}} ->
          conn
          |> put_flash(
            :success,
            "Pick report attendance was successfully submitted. Please fill out fruit info next."
          )
          |> redirect(to: Routes.pick_report_path(conn, :fruit, pick))

        {:error, :pick_report, %Ecto.Changeset{} = changeset, _} ->
          conn
          |> put_flash(:error, "There was an error submitting the report.")
          |> render("new.html",
            pick: pick,
            changeset: changeset
          )
      end
    else
      conn
      |> put_flash(:error, "You don't have permission to create this report")
      |> redirect(to: pick_path(conn, me, pick))
    end
  end

  def fruit(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    me = conn.assigns.current_person

    cond do
      is_map(pick.report) and pick.report.is_complete ->
        conn
        |> put_flash(:error, "The pick report is already complete.")
        |> redirect(to: pick_path(conn, me, pick))

      is_map(pick.report) and can_edit?(pick, me) ->
        case Activities.get_pick_report_by_pick_id(pick_id) do
          %PickReport{} = pick_report ->
            fruit_changesets = setup_fruit_changesets(pick)

            agencies =
              Partners.list_agencies_available_to_report(
                pick.scheduled_date,
                pick.scheduled_start_time
              )
              |> generate_options()

            changeset =
              PickReport.changeset(pick_report, %{})
              |> Ecto.Changeset.put_assoc(:fruits, fruit_changesets)

            render(conn, "fruit.html",
              pick: pick,
              changeset: changeset,
              agencies: agencies
            )

          nil ->
            conn
            |> put_flash(:error, "You must submit the attendance for the report first.")
            |> redirect(to: Routes.pick_report_path(conn, :new, pick))
        end

      true ->
        conn
        |> put_flash(:error, "You must submit the attendance for the report first.")
        |> redirect(to: pick_path(conn, me, pick))
    end
  end

  def report_fruit(conn, %{"pick_report" => report_params, "pick_id" => pick_id} = params) do
    pick = Activities.get_pick!(pick_id)
    me = conn.assigns.current_person

    if is_map(pick.report) and can_edit?(pick, me) do
      pick_report = Activities.get_pick_report_by_pick_id(pick_id)

      case Activities.complete_report(pick.report, report_params) do
        {:ok, report} ->
          if has_issue?(report) do
            email_admin_report_issue(pick)
          end

          Task.start(fn ->
            Email.pick_completion_tree_owner_email(pick)
            |> Mailer.deliver_later()
          end)

          conn
          |> put_flash(:info, "Pick report was successfully completed.")
          |> redirect(to: pick_path(conn, me, pick))

        {:error, %Ecto.Changeset{} = changeset} ->
          agencies =
            Partners.list_agencies_available_to_report(
              pick.scheduled_date,
              pick.scheduled_start_time
            )
            |> generate_options()

          {_, fpa_changeset_insert} =
            PickFruitAgency.changeset(%PickFruitAgency{}, %{})
            |> apply_action(:insert)

          fpa_changeset = PickFruitAgency.changeset(%PickFruitAgency{}, %{})

          new_changeset =
            Enum.map(changeset.changes.fruits, fn fp_changeset ->
              case Map.has_key?(fp_changeset.changes, :agencies) do
                false ->
                  fp_changeset

                  Map.put(
                    fp_changeset,
                    :changes,
                    Map.merge(
                      fp_changeset.changes,
                      Map.put(fp_changeset.changes, :agencies, [
                        fpa_changeset_insert,
                        fpa_changeset,
                        fpa_changeset,
                        fpa_changeset
                      ])
                    )
                  )

                _ ->
                  fp_changeset
              end
            end)

          new_changeset = Map.put(changeset.changes, :fruits, new_changeset)
          new_changeset = Map.put(changeset, :changes, new_changeset)

          conn
          |> put_flash(:error, "There was an error completing the report.")
          |> render("fruit.html",
            pick: pick,
            changeset: new_changeset,
            agencies: agencies
          )
      end
    else
      conn
      |> put_flash(:error, "You don't have permission to finish this report")
      |> redirect(to: pick_path(conn, me, pick))
    end
  end

  defp setup_fruit_changesets(%Pick{} = pick) do
    pick.trees
    |> Enum.map(fn tree -> tree.type end)
    |> Enum.sort()
    |> Enum.chunk_by(fn type -> type end)
    |> Enum.map(fn tree_type_list ->
      if length(tree_type_list) > 1 do
        "#{hd(tree_type_list)} x#{length(tree_type_list)}"
      else
        hd(tree_type_list)
      end
    end)
    |> Enum.map(fn tt ->
      PickFruit.changeset(
        %PickFruit{
          agencies: [
            %PickFruitAgency{},
            %PickFruitAgency{},
            %PickFruitAgency{},
            %PickFruitAgency{}
          ]
        },
        %{
          fruit_category: tt,
          pick_id: pick.id,
          pick_report_id: pick.report.id
        }
      )
    end)
  end

  defp has_issue?(%PickReport{} = report) do
    report.has_equipment_set_issue or
      not report.has_fruit_delivered_to_agency or
      report.has_issues_on_site
  end

  defp email_admin_report_issue(%Pick{} = pick) do
    admins = Repo.all(Person.admins())

    Enum.each(admins, fn a ->
      a
      |> Email.admin_report_issue(pick)
      |> Mailer.deliver_later()
    end)
  end

  defp generate_options(list) do
    Enum.map(list, &{"#{&1.name} (#{&1.closest_intersection})", &1.id})
  end

  defp pick_path(conn, me, pick) do
    if is_admin?(me) do
      Routes.admin_pick_path(conn, :show, pick)
    else
      Routes.pick_path(conn, :show, pick)
    end
  end

  defp is_admin?(%Person{} = person) do
    person.role == :admin
  end

  def can_edit?(pick, me) do
    pick.lead_picker.id == me.id || is_admin?(me)
  end
end
