defmodule Server.Router do
  use Plug.Router
  
  plug :match
  plug :dispatch

  post "/api/request-file-list" do
    files = Server.CentralServer.request_file_list()
    send_resp(conn, 200, Jason.encode!(%{
      status: "ok",
      message: "Broadcast sent to all clients",
      files: files
    }))
  end

  post "/api/register" do
    {:ok, _body, _conn} = Plug.Conn.read_body(conn)
    ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")
    client_id = Server.CentralServer.register_client(ip)
    send_resp(conn, 200, Jason.encode!(%{status: "ok", client_id: client_id}))
  end

  post "/api/request-file" do
    ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    %{"file" => file, "version" => version} = Jason.decode!(body)
    IO.puts("Request received for file: #{file} version: #{version}")

    files = Server.CentralServer.request_file(ip, file, version)
    
    send_resp(conn, 200, Jason.encode!(%{
      status: "ok",
      message: "Request sent to all clients for file version",
      files: files
    }))
  end

  post "/api/receive-file" do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    %{"file" => file, "version" => version, "file_data" => file_data} = Jason.decode!(body)

    IO.puts("Received file '#{file}' version #{version} from client. Data length: #{String.length(file_data)}")

    Server.CentralServer.receive_file(file, version, file_data)

    send_resp(conn, 200, Jason.encode!(%{status: "ok", message: "File received successfully"}))
  end

  post "/api/unregister" do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    %{"client_id" => client_id} = Jason.decode!(body)
    Server.CentralServer.unregister_client(client_id)
    send_resp(conn, 200, Jason.encode!(%{status: "ok"}))
  end

  get "/api/clients" do
    clients = Server.CentralServer.list_clients()
    send_resp(conn, 200, Jason.encode!(%{clients: clients}))
  end

  match _ do
    send_resp(conn, 404, "Oops! Page not found")
  end
end
