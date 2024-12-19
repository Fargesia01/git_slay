defmodule Client.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ClientWeb.Telemetry,
      {Phoenix.PubSub, name: Client.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Client.Finch},
      # Start a worker by calling: Client.Worker.start_link(arg)
      # {Client.Worker, arg},
      # Start to serve requests, typically the last entry
      ClientWeb.Endpoint,
      {Task, fn -> register_client() end}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Client.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Automatically registers the client on startup
  defp register_client do 
    map = %{"project.ex" => 5}
    Application.put_env(:client, :remote_files, map)
    ip  = "127.0.0.1"
    url = "http://192.168.1.11:5000/api/register"

    body = Jason.encode!(%{
      "ip" => ip
    })

    case HTTPoison.post(url, body, [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> 
        case Jason.decode(body) do
          {:ok, %{"client_id" => client_id}} ->
            IO.puts("Successfully registered client #{client_id}")
            Application.put_env(:client, :client_id, client_id)
          {:error, reason} -> 
            IO.puts("Failed to parse client ID: #{inspect(reason)}")
        end
      {:error, %HTTPoison.Error{reason: reason}} -> 
        IO.puts("Failed to register the client: #{inspect(reason)}")
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ClientWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
