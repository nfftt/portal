{:ok, _} = Application.ensure_all_started(:ex_machina)

# Use the TAP protocol when running tests on CI
if System.get_env("DATABASE_URL") do
  ExUnit.configure formatters: [Tapex]
end

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(FruitPicker.Repo, :manual)
