defmodule Server.CentralServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: {:global, __MODULE__})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def register_client(client_id, ip) do
    GenServer.call({:global, __MODULE__}, {:register_client, client_id, ip})
  end

  def list_clients do
    GenServer.call({:global, __MODULE__}, :list_clients)
  end

  @impl true
  def handle_call({:register_client, client_id, ip}, _from, state) do
    new_state = Map.put(state, client_id, ip)
    IO.puts("Registered client: #{client_id} with IP: #{ip}")
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:list_clients, _from, state) do
    {:reply, state, state}
  end
end
