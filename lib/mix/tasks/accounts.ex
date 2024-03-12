defmodule Mix.Tasks.Accounts do
  use Mix.Task

  import FruitPicker.Tasks.Accounts, only: [update_all: 0]

  def run(_args) do
    Mix.Task.run("app.start")
    update_all()
  end
end
