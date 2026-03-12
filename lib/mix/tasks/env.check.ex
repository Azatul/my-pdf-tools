defmodule Mix.Tasks.Env.Check do
  @shortdoc "Checks if .env is loaded (vars set without printing values)"
  @moduledoc """
  Runs after config is loaded so that .env has been applied.
  Prints whether each expected var is set (values are not shown).
  """
  use Mix.Task

  @vars ~w(DATABASE_PASSWORD PGPASSWORD PGUSER PGHOST)

  @impl Mix.Task
  def run(_args) do
    # Ensure config (and thus .env) is loaded
    Mix.Task.reenable("loadconfig")
    Mix.Task.run("loadconfig")

    env_path = Path.join(File.cwd!(), ".env")
    if File.exists?(env_path) do
      IO.puts("✓ .env file found")
    else
      IO.puts("✗ .env file not found")
    end

    IO.puts("")
    IO.puts("Environment variables (value hidden):")
    for key <- @vars do
      value = System.get_env(key)
      status = if value != nil && value != "", do: "set", else: "(not set)"
      IO.puts("  #{key}: #{status}")
    end
  end
end
