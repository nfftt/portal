import Config

# Do not print debug messages in production
config :logger,
  level: :info

# Configure Sentry
config :sentry,
  environment_name: :prod
