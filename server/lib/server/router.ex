defmodule Server.Router do
  use Plug.Router
  
  plug :match
  plug :dispatch

  post "/api/register" do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    %{"client_id" => client_id, "ip" => ip} = Jason.decode!(body)
    Server.CentralServer.register_client(client_id, ip)
    send_resp(conn, 200, Jason.encode!(%{status: "ok", message: "Client registered successfully"}))
  end

  get "/api/clients" do
    clients = Server.CentralServer.list_clients()
    send_resp(conn, 200, Jason.encode!(%{clients: clients}))
  end

  match _ do
    send_resp(conn, 404, "Oops! Page not found")
  end
end
