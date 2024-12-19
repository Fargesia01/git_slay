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

    responses = 
      state.clients
      |> Enum.map(fn {_client_id, %{ip: ip}} -> 
        url = "http://#{ip}:4000/api/list-local-files"
        Task.async(fn -> 
          case HTTPoison.post(url, "", [{"Content-Type", "application/json"}]) do
            {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} -> 
              {:ok, Jason.decode!(response_body)["files"]}
            {:error, %HTTPoison.Error{reason: reason}} -> 
              {:error, reason}
          end
        end)
      end)

      |> Enum.map(fn task -> 
        case Task.yield(task, 5000) do
          {:ok, result} -> result
          nil -> 
            Task.shutdown(task, :brutal_kill)
            {:error, :timeout}
        end
      end)

    aggregated_files = 
      responses 
      |> Enum.filter(fn 
        {:ok, _files} -> true
        _ -> false 
      end)
      |> Enum.map(fn {:ok, files} -> files end)
      |> Enum.reduce(%{}, fn file_map, acc -> Map.merge(acc, file_map) end)

    IO.puts("Aggregated file list: #{inspect(aggregated_files)}")

    {:reply, aggregated_files, new_state}
  end

  @impl true
  def handle_call(:list_clients, _from, state) do
    {:reply, state, state}
  end
end
