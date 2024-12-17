defmodule Server.Router do
  use Plug.Router
  
  plug :match
  plug :dispatch

  post "/api/request-file-list" do
    ip = Tuple.to_list(conn.remote_ip) |> Enum.join(".")
    Server.CentralServer.request_file_list(ip)
    send_resp(conn, 200, Jason.encode!(%{status: "ok", message: "Broadcast sent to all clients"}))
  end

  post "/api/send-file-list" do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    %{"client_id" => client_id, "file_list" => file_list} = Jason.decode!(body)

    Server.CentralServer.receive_file_list(client_id, file_list)
    send_resp(conn, 200, Jason.encode!(%{status: "ok", message: "File list received"}))
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
