import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :fruit_picker, FruitPickerWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
if System.get_env("DATABASE_URL") do
  config :fruit_picker, FruitPicker.Repo,
    adapter: Ecto.Adapters.Postgres,
    url: System.get_env("DATABASE_URL"),
    connect_timeout: 20_000,
    pool: Ecto.Adapters.SQL.Sandbox
else
  config :fruit_picker, FruitPicker.Repo,
    username: "postgres",
    password: "postgres",
    database: "fruit_picker_test",
    hostname: "localhost",
    pool: Ecto.Adapters.SQL.Sandbox
end

# Configure Mailer
config :fruit_picker, FruitPicker.Mailer,
  adapter: Bamboo.TestAdapter

# Configure file uploads
config :arc,
  storage: Arc.Storage.Local,
  storage_dir: "priv/uploads"

# Disable Mapbox
config :fruit_picker, :mapbox, disabled: true
