defmodule FruitPickerWeb.Plugs.ScheduledDowntime do
  import Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    if Application.get_env(:fruit_picker, :scheduled_downtime) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(
        503,
        "Not Far From The Tree is undergoing scheduled maintenance. Please check back soon."
      )
      |> halt()
    else
      conn
    end
  end
end
