defmodule Mix.Tasks.Coordinates do
  @moduledoc """
  Scheduled job functions for fetching lat/long for locations.
  """

  use Mix.Task

  import FruitPicker.Tasks.Coordinates, only: [update_all: 0]

  def run(_args) do
    Mix.Task.run("app.start")
    update_all()
  end
end
