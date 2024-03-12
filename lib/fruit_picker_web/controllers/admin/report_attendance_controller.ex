defmodule FruitPickerWeb.Admin.ReportAttendanceController do
  use FruitPickerWeb, :controller

  import Ecto.Query, warn: false

  alias FruitPicker.Accounts.{
    Person,
    Property,
    Tree
  }

  alias FruitPicker.Partners.Agency

  alias FruitPicker.Activities

  alias FruitPicker.Activities.{
    Pick,
    PickAttendance
  }

  alias FruitPicker.Stats
  alias FruitPicker.Repo

  def new(conn, _params) do
    season_years = Activities.get_season_years()
    render(conn, "new.html", season_years: season_years)
  end

  def create(conn, %{"year" => year}) do
    season_years = Activities.get_season_years()
    data = Activities.get_picker_information_and_attendance(year)

    csv_header = [:first_name, :last_name, :role, :is_active, :email, :attended, :led]

    conn =
      conn
      |> put_resp_header("content-disposition", "attachment;filename=Report#{year}.csv")
      |> put_resp_content_type("text/csv")
      |> send_chunked(200)

    {:ok, conn} =
      Repo.transaction(fn ->
        data
        |> Stream.map(&parse/1)
        |> (fn stream -> Stream.concat([csv_header], stream) end).()
        |> CSV.encode()
        |> Enum.into(File.stream!("Report#{year}.csv", [:write, :utf8]))
        |> Enum.reduce_while(conn, fn data, conn ->
          case chunk(conn, data) do
            {:ok, conn} ->
              {:cont, conn}

            {:error, :closed} ->
              {:halt, conn}
          end
        end)
      end)

    File.rm("Report#{year}.csv")
    conn
  end

  defp parse(row) do
    Enum.map(~w( first_name last_name role is_active email attended led )a, &Map.get(row, &1))
  end
end
