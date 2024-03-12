defmodule FruitPickerWeb.FallbackController do
  @moduledoc """
    Actions for handling controller errors.
  """

  alias FruitPickerWeb.ErrorView

  use Phoenix.Controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthenticated}, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: Router.Helpers.auth_path(conn, :request))
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(403)
    |> put_view(ErrorView)
    |> render(:"403")
  end
end
