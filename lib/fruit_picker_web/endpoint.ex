defmodule FruitPickerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :fruit_picker
  use Sentry.PlugCapture

  plug FruitPickerWeb.Plugs.ScheduledDowntime

  # socket "/socket", FruitPickerWeb.UserSocket,
  #   websocket: true,
  #   longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  #

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  #
  @session_options [
    store: :cookie,
    key: "_fruit_picker_key",
    signing_salt: "ELGzPiS7"
  ]

  plug Plug.Session, @session_options

  plug Plug.Static,
    at: "/",
    from: :fruit_picker,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  if Mix.env() == :dev do
    plug Plug.Static,
      at: "/uploads",
      from: {:fruit_picker, "priv/uploads"},
      gzip: false,
      headers: %{"Accept-Ranges" => "bytes"}
  end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["text/*"],
    body_reader: {FruitPicker.CacheBodyReader, :read_body, []},
    json_decoder: Phoenix.json_library()

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Sentry.PlugContext

  plug Plug.MethodOverride
  plug Plug.Head

  plug FruitPickerWeb.Router

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]
end
