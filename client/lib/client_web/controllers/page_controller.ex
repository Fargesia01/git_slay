defmodule ClientWeb.PageController do
  use ClientWeb, :controller

  def home(conn, _params) do
    local_files = Client.Backend.list_local_files()
    all_files = Client.Backend.list_all_files()
    render(conn, :home, local_files: local_files, all_files: all_files)
  end

  def shutdown(_conn, _params) do
    IO.puts("Shutdown asked. Stopping the app...")
    unregister_client()
    System.halt(0)
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