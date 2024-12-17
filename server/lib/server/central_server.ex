defmodule Server.CentralServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: {:global, __MODULE__})
  end

  @impl true
  def init(_state) do
    initiale_state = %{
      counter: 0,
      clients: %{},
      request_results: %{},
      current_request: nil
    }
    {:ok, initiale_state}
  end

  # Server callbacks

  def register_client(ip) do
    GenServer.call({:global, __MODULE__}, {:register_client, ip})
  end

  def unregister_client(client_id) do
    GenServer.call({:global, __MODULE__}, {:unregister_client, client_id})
  end

  def request_file_list(request_ip) do
    GenServer.call({:global, __MODULE__}, {:request_file_list, request_ip})
  end

  def receive_file_list(client_id, file_list) do
    GenServer.call({:global, __MODULE__}, {:receive_file_list, client_id, file_list})
  end

  def list_clients do
    GenServer.call({:global, __MODULE__}, :list_clients)
  end

  # Implementations

  @impl true
  def handle_call({:register_client, ip}, {from_pid, _}, state) do
    client_id = "client_#{state.counter + 1}"
    new_clients = Map.put(state.clients, client_id, %{ip: ip, pid: from_pid})
    new_state = %{state | counter: state.counter + 1, clients: new_clients}

    IO.puts("Registered client: #{client_id} with IP: #{ip}")

    {:reply, client_id, new_state}
  end

  @impl true
  def handle_call({:unregister_client, client_id}, _from, state) do
    new_clients = Map.delete(state.clients, client_id)
    new_state = %{state | clients: new_clients}
    IO.puts("Unregistered client: #{client_id}")
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:request_file_list, request_ip}, _from, state) do
    IO.puts("Broadcasting 'list_local_files' request to all client...")

    new_state = %{
      state | request_results: %{}, current_request: request_ip
    }

    Enum.each(state.clients, fn {_client_id, %{ip: ip}} -> 
      url = "http://#{ip}:4000/api/list-local-files"
      Task.start(fn -> 
        HTTPoison.post(url, "", [{"Content-Type", "application/json"}])
      end)
    end)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:receive_file_list, client_id, file_list}, _from, state) do
    IO.puts("Received file list from #{client_id}: #{inspect(file_list)}")

    IO.inspect(state.current_request)
    new_state = Map.update(state, :request_results, %{}, fn request_results -> 
      Map.update(request_results, client_id, [file_list], fn existing_files -> 
        [file_list | existing_files]
      end)
    end)

    if all_clients_responded?(state.clients, new_state.request_results) do
      IO.puts("All clients have responded. Aggregating...")

      aggregated_files_list = aggregate_file_results(new_state.request_results)
      send_response_to_requester(new_state.current_request, aggregated_files_list)
    end

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:list_clients, _from, state) do
    {:reply, state, state}
  end

  # HELPER FUNCTIONS

  defp all_clients_responded?(clients, request_results) do
    Map.keys(clients) -- Map.keys(request_results) == []
  end

  defp aggregate_file_results(results) do
    results
    |> Map.values()
    |> List.flatten()
    |> Enum.uniq()
  end

  defp send_response_to_requester(requester_ip, aggregated_files_list) do
    IO.puts(requester_ip)
    url = "http://127.0.0.1:4000/api/file-list-response"
    body = Jason.encode!(%{files: aggregated_files_list})

    IO.puts("Sending aggregated file list to requester")
    HTTPoison.post(url, body, [{"Content-Type", "application/json"}])
  end
end
