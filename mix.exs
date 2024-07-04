defmodule FruitPicker.MixProject do
  use Mix.Project

  def project do
    [
      app: :fruit_picker,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [coveralls: :test],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {FruitPicker.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :bamboo,
        :scrivener_ecto,
        :scrivener_html,
        :ueberauth,
        :ueberauth_identity
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:arc_ecto, "~> 0.11"},
      {:argon2_elixir, "~> 2.0"},
      {:bamboo, "~> 1.2"},
      {:brady, "~> 0.0.7"},
      {:comeonin, "~> 5.0"},
      {:csv, "~> 2.4"},
      {:ecto_enum, "~> 1.2"},
      {:ecto_sql, "~> 3.0"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:floki, "~> 0.30.0"},
      {:gettext, "~> 0.11"},
      {:hashids, "~> 2.0"},
      {:httpoison, "~> 2.2"},
      {:phoenix, "~> 1.6.0"},
      {:phoenix_active_link, github: "digitalnativescreative/phoenix-active-link"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.17"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_slime, github: "digitalnativescreative/phoenix_slime"},
      {:plug_cowboy, "~> 2.3"},
      {:policy_wonk, "~> 1.0.0"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.1"},
      {:quantum, "~> 3.0"},
      {:quinn, "~> 1.1"},
      {:recase, "~> 0.5"},
      {:inflex, "~> 2.0.0"},
      {:scrivener_ecto, "~> 2.7"},
      {:scrivener_html, github: "digitalnativescreative/scrivener_html"},
      {:sentry, "~> 8.0"},
      {:stripity_stripe, "~> 2.7"},
      {:sweet_xml, "~> 0.6"},
      {:timex, "~> 3.7.5"},
      {:ueberauth, "~> 0.10.8"},
      {:ueberauth_identity, "~> 0.3.0"},
      {:xml_builder, "~> 2.1"},
      {:dotenv_parser, "~> 2.0"},
      {:credo, "~> 1.5.5", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_machina, "~> 2.3", only: :test},
      {:mock, "~> 0.3.0", only: :test},
      {:tapex, "~> 0.1.0", only: :test},
      {:faker, "~> 0.17", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.pr": ["ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.heroku": ["ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test.local": ["ecto.create --quiet", "ecto.migrate", "test"],
      test: ["ecto.migrate", "test"]

      #      "assets.deploy": ["cmd --cd assets npm run deploy", "phx.digest"]
    ]
  end
end
