# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :fruit_picker,
  ecto_repos: [FruitPicker.Repo]

# Configures the endpoint
config :fruit_picker, FruitPickerWeb.Endpoint,
  url: [host: "localhost"],
  static_url: [host: "localhost"],
  live_view: [signing_salt: "GRkuBfM3qVSoWUiDiAyvCrlnXtdtdI8c"],
  secret_key_base: "IviZBYPZnRFF/YtqQT0QPqcVanoHGeQzFryWp+1rCO5fY+IKRm366qki9UbCXPHu",
  render_errors: [view: FruitPickerWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: FruitPicker.PubSub

config :fruit_picker, FruitPicker.Repo, log: false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  backends: [:console],
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine

config :ueberauth, Ueberauth,
  providers: [
    identity:
      {Ueberauth.Strategy.Identity,
       [
         callback_methods: ["POST"],
         request_path: "/signin",
         callback_path: "/signin"
       ]}
  ]

config :brady,
  otp_app: :fruit_picker,
  svg_path: "priv/static/images"

config :scrivener_html,
  routes_helper: FruitPicker.Router.Helpers,
  view_style: :bulma

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
