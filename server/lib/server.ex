defmodule Server do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Server.CentralServer, []},
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Server.Router,
        options: [port: 5000]
      )
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
