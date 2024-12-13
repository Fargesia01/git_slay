defmodule GitSlay.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GitSlayWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:git_slay, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GitSlay.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: GitSlay.Finch},
      # Start a worker by calling: GitSlay.Worker.start_link(arg)
      # {GitSlay.Worker, arg},
      # Start to serve requests, typically the last entry
      GitSlayWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GitSlay.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GitSlayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
