import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/<%= @app_name %> start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :fruit_picker, FruitPickerWeb.Endpoint, server: true
end

if config_env == :dev do
  DotenvParser.load_file(".env.local")
end

config :stripity_stripe, api_key: System.get_env("STRIPE_SECRET_KEY")

config :fruit_picker,
       :stripe_pub_key,
       System.get_env("STRIPE_PUB_KEY")

config :fruit_picker,
       :stripe_webhook_secret,
       System.get_env("STRIPE_WEBHOOK_SECRET")

config :fruit_picker, :scheduled_downtime, System.get_env("SCHEDULED_DOWNTIME") == "true"

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.

  config :fruit_picker, FruitPickerWeb.Endpoint,
    load_from_system_env: true,
    url: [host: System.get_env("PHX_HOST"), port: 443, scheme: "https"],
    http: [:inet6, port: System.get_env("PORT") || 4000],
    static_url: [
      scheme: System.get_env("URL_SCHEME") || "https",
      host: System.get_env("URL_STATIC_HOST"),
      port: System.get_env("URL_PORT") || 443
    ],
    force_ssl: [rewrite_on: [:x_forwarded_proto]],
    cache_static_manifest: "priv/static/cache_manifest.json",
    secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE")

  # Configure your database
  config :fruit_picker, FruitPicker.Repo,
    adapter: Ecto.Adapters.Postgres,
    socket_options: [:inet6],
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    url: System.get_env("DATABASE_URL")

  # Configure Mailer
  if System.get_env("DISABLE_MAILGUN") do
    config :fruit_picker, FruitPicker.Mailer, adapter: Bamboo.LocalAdapter
  else
    config :fruit_picker, FruitPicker.Mailer,
      adapter: Bamboo.MailgunAdapter,
      api_key: System.get_env("MAILGUN_API_KEY"),
      domain: System.get_env("MAILGUN_DOMAIN")
  end

  # Configure file uploads
  config :arc,
    storage: Arc.Storage.S3,
    virtual_host: false,
    bucket: System.get_env("SPACES_BUCKET"),
    storage_dir: "/uploads",
    asset_host: "https://jj-apps.nyc3.digitaloceanspaces.com/#{System.get_env("SPACES_BUCKET")}"

  config :ex_aws,
    access_key_id: System.get_env("SPACES_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("SPACES_SECRET_ACCESS_KEY"),
    region: "nyc3",
    s3: [
      scheme: "https://",
      host: System.get_env("SPACES_HOST")
    ]

  # Configure Sentry
  config :sentry,
    dsn: System.get_env("SENTRY_DSN"),
    included_environments: [:prod],
    environment_name: System.get_env("SENTRY_ENV_NAME") |> String.to_atom(),
    enable_source_code_context: true,
    root_source_code_path: File.cwd!()

  # Configure env keys
  config :fruit_picker,
         :google_analytics_id,
         System.get_env("GOOGLE_ANALYTICS")

  config :fruit_picker,
         :mapbox_api_key,
         System.get_env("MAPBOX_API_KEY")

  config :fruit_picker,
         :mailchimp_api_key,
         System.get_env("MAILCHIMP_API_KEY")

  config :fruit_picker,
         :sentry_dsn,
         System.get_env("SENTRY_DSN")

  config :fruit_picker,
         :sentry_dsn_js,
         System.get_env("SENTRY_DSN_JS")

  # Configure the Scheduler
  config :fruit_picker, FruitPicker.Scheduler,
    jobs: [
      # Update all coordinates daily at 5am UTC
      {"0 5 * * *", {FruitPicker.Tasks.Coordinates, :update_all, []}},
      # Email about picks daily at 11am and 10:00pm UTC
      {"0 11 * * *", {FruitPicker.Tasks.Picks.PickersDailyEmail, :send_out_email, []}},
      {"00 22 * * *", {FruitPicker.Tasks.Picks.PickersDailyEmail, :send_out_email, []}},
      # Mark picks as complete every hour on the 20 minute mark
      {"20 * * * *", {FruitPicker.Tasks.Picks.Complete, :complete_picks, []}},
      # Send out Pick Report Reminder daily at 12:00pm UTC
      # Currently Disabled (see https://github.com/nfftt/fruit-picker/issues/74)
      # {"0 12 * * *", {FruitPicker.Tasks.Picks.ReportReminder, :send_out_email, []}},
      # Send out  Pick Reminder daily at 11:30am UTC
      {"0 12 * * *", {FruitPicker.Tasks.Picks.Reminders, :pick_reminders, []}}
    ]

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :<%= @web_app_name %>, <%= @endpoint_module %>,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :<%= @web_app_name %>, <%= @endpoint_module %>,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.<%= if @mailer do %>

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :<%= @app_name %>, <%= @app_module %>.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.<% end %>
end
