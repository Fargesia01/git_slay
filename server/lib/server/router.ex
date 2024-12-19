defmodule Server.Router do
  use Plug.Router
  
  plug :match
  plug :dispatch

  post "/api/request-file-list" do
    ip = Tuple.to_list(conn.remote_ip) |> Enum.join(".")
    files = Server.CentralServer.request_file_list(ip)
    send_resp(conn, 200, Jason.encode!(%{
      status: "ok",
      message: "Broadcast sent to all clients",
      files: files
    }))
  end

  post "/api/register" do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    %{"ip" => ip} = Jason.decode!(body)
    client_id = Server.CentralServer.register_client(ip)
    send_resp(conn, 200, Jason.encode!(%{status: "ok", client_id: client_id}))
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
