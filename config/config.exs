# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# Load .env in dev/test so DATABASE_PASSWORD etc. are set before env-specific config runs.
# Done inline (no dependency) because config.exs runs before deps are compiled.
if Mix.env() in [:dev, :test] do
  env_path = Path.join(File.cwd!(), ".env")
  if File.exists?(env_path) do
    env_path
    |> File.read!()
    |> String.split(~r/\r?\n/, trim: false)
    |> Enum.each(fn line ->
      line = String.trim(line)
      if line != "" and not String.starts_with?(line, "#") do
        case String.split(line, "=", parts: 2) do
          [key, value] ->
            key = key |> String.trim() |> String.trim_leading("export ")
            value = value |> String.trim() |> String.trim_leading("\"") |> String.trim_trailing("\"")
            if key != "", do: System.put_env(key, value)
          _ -> :ok
        end
      end
    end)
  end
end

# General application configuration
import Config

config :my_pdf_tools,
  ecto_repos: [MyPdfTools.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :my_pdf_tools, MyPdfToolsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MyPdfToolsWeb.ErrorHTML, json: MyPdfToolsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MyPdfTools.PubSub,
  live_view: [signing_salt: "mOFzG7Cj"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :my_pdf_tools, MyPdfTools.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  my_pdf_tools: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  my_pdf_tools: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
