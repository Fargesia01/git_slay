defmodule Server.CentralServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: {:global, __MODULE__})
  end

  @impl true
  def init(_state) do
    initiale_state = %{
      counter: 0,
      clients: %{}
    }
    {:ok, initiale_state}
  end

  def register_client(ip) do
    GenServer.call({:global, __MODULE__}, {:register_client, ip})
  end

  def list_clients do
    GenServer.call({:global, __MODULE__}, :list_clients)
  end

  @impl true
  def handle_call({:register_client, ip}, {from_pid, _}, state) do
    client_id = "client_#{state.counter + 1}"
    new_clients = Map.put(state.clients, client_id, %{ip: ip, pid: from_pid})
    new_state = %{state | counter: state.counter + 1, clients: new_clients}

    IO.puts("Registered client: #{client_id} with IP: #{ip}")

    {:reply, client_id, new_state}
  end

  @impl true
  def handle_call(:list_clients, _from, state) do
    {:reply, state, state}
  end
end
