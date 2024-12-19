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

  def list_local_files(conn, _params) do
    file_list = Client.Backend.list_remote_files()
    IO.puts("Client sending file list: #{inspect(file_list)}")

    Client.Backend.send_file_list_to_server(file_list)
    json(conn, %{status: "ok", files: file_list})
  end

  def file_list_response(conn, %{"files" => files}) do
    IO.puts("Files accross network received: #{inspect(files)}")
    json(conn, %{status: "ok"})
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
