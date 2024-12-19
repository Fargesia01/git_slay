defmodule ClientWeb.PageController do
  use ClientWeb, :controller

  def home(conn, _params) do
    local_files = Client.Backend.list_local_files()
    all_files = Client.Backend.list_all_files()
    render(conn, :home, local_files: local_files, all_files: all_files)
  end

  def commit(conn, %{"file" => file}) do
    case Client.Backend.commit(file) do
      :ok -> 
        json(conn, %{status: "ok", message: "File committed successfully"})
      {:error, reason} -> 
        json(conn, %{status: "error", message: "Failed to commit file", reason: reason})
    end
  end

  def shutdown(_conn, _params) do
    IO.puts("Shutdown asked. Stopping the app...")
    unregister_client()
    System.halt(0)
  end

  def pull_recent(conn, %{"file" => file}) do
    remote_files = Application.get_env(:client, :remote_files, %{})
    version = Map.get(remote_files, file, 0)

    url = "http://192.168.1.11:5000/api/request-file"
    body = Jason.encode!(%{file: file, version: version})

    case HTTPoison.post(url, body, [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200}} -> 
        json(conn, %{status: "ok", message: "Request sent for most recent version."})
      {:error, %HTTPoison.Error{reason: reason}} -> 
        json(conn, %{status: "error", message: "Request failed.", reason: inspect(reason)})
    end
  end

  def pull_specific(conn, %{"file" => file, "version" => version}) do
    url = "http://192.168.1.11:5000/api/request-file"
    body = Jason.encode!(%{file: file, version: version})

    case HTTPoison.post(url, body, [{"Content-Type", "application/json"}]) do
      {:ok, %HTTPoison.Response{status_code: 200}} -> 
        json(conn, %{status: "ok", message: "Request sent for specific version."})
      {:error, %HTTPoison.Error{reason: reason}} -> 
        json(conn, %{status: "error", message: "Request failed.", reason: inspect(reason)})
    end
  end

  def get_file(conn, %{"file" => file, "version" => version}) do
    IO.puts("Received request for file '#{file}' version #{version}.")

    file_data = Client.Backend.get_file(file, version)
    
    if file_data do
      url = "http://192.168.1.11:5000/api/receive-file"
      body = Jason.encode!(%{file: file, version: version, file_data: file_data})

      case HTTPoison.post(url, body, [{"Content-Type", "application/json"}]) do
        {:ok, %HTTPoison.Response{status_code: 200}} -> 
          IO.puts("Successfully sent file '#{file}' version #{version} to the server.")
        {:error, %HTTPoison.Error{reason: reason}} -> 
          IO.puts("Failed to send file: Reason: #{inspect(reason)}")
      end
    else
      IO.puts("File '#{file}' version #{version} not found.")
    end
    json(conn, %{status: "ok"})
  end

  def receive_file(conn, %{"file" => file, "version" => version, "file_data" => file_data}) do
    IO.puts("Received file '#{file}' version #{version} from server.")
    IO.inspect(file_data)
    Client.Backend.put_in_local(file, version, file_data)
    json(conn, %{status: "ok"})
  end

  def list_local_files(conn, _params) do
    file_list = Client.Backend.list_remote_files()
    IO.puts("Client sending file list: #{inspect(file_list)}")

    json(conn, %{status: "ok", files: file_list})
  end

  # Unregister the client when app shuts down
  defp unregister_client do
    client_id = Application.get_env(:client, :client_id)

    if client_id do
      url = "http://192.168.1.11:5000/api/unregister"
      body = Jason.encode!(%{"client_id" => client_id})

      case HTTPoison.post(url, body, [{"Content-Type", "application/json"}]) do
        {:ok, %HTTPoison.Response{status_code: 200}} -> 
          IO.puts("Successfully unregistered client #{client_id}")
        {:error, %HTTPoison.Error{reason: reason}} -> 
          IO.puts("Failed to unregister the client: #{inspect(reason)}")
      end
    else
      IO.puts("Client ID not found, cannot unregister")
    end
  end
end
