defmodule FruitPickerWeb.LayoutView do
  use FruitPickerWeb, :view
  alias FruitPickerWeb.{PageTitle, SharedView, Policies}

  def page_title(conn) do
    view = view_module(conn)
    action = action_name(conn)
    PageTitle.for_view({view, action, conn.assigns})
  end

  def sentry_dsn do
    Application.get_env(:fruit_picker, :sentry_dsn, "")
  end

  def sentry_dsn_js do
    Application.get_env(:fruit_picker, :sentry_dsn_js, "")
  end

  def google_analytics_id do
    Application.get_env(:fruit_picker, :google_analytics_id)
  end
end

defmodule FruitPickerWeb.PageTitle do
  # alias FruitPickerWeb.{PageView}
  @app_name "Fruit Picking Portal"

  def for_view({view, action, assigns}) do
    {view, action, assigns}
    |> get()
    |> add_app_name()

  end

  # defp get({SessionView, :new, _}) do
  #   "Signin"
  # end

  defp get(_), do: nil

  defp add_app_name(nil), do: @app_name
  defp add_app_name(title), do: "#{title} - #{@app_name}"
end
