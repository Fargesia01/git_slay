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

  defp register_client do 
    client_id = "web_client_#{:rand.uniform(1000)}"
    ip = "127.0.0.1"
    url = "http://127.0.0.1:5000/api/register"

    body = Jason.encode!(%{
      "client_id" => client_id,
      "ip" => ip
    })

    case HTTPoison.post(url, body, [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200}} -> 
        IO.puts("Successfully registered client #{client_id}")
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
