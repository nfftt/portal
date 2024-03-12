defmodule FruitPickerWeb.DonationController do
  use FruitPickerWeb, :controller

  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.Donation

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
