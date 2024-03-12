defmodule FruitPickerWeb.PageController do
  use FruitPickerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
