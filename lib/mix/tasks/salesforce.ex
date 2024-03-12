defmodule Mix.Tasks.Salesforce do
  use Mix.Task

  import FruitPicker.Tasks.Salesforce, only: [update_all_people: 0]

  def run(_args) do
    Mix.Task.run("app.start")
    update_all_people()
  end
end
