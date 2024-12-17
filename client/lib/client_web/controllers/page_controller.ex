defmodule ClientWeb.PageController do
  use ClientWeb, :controller

  def home(conn, _params) do
    local_files = Client.Backend.list_local_files()
    all_files = Client.Backend.list_all_files()
    render(conn, :home, local_files: local_files, all_files: all_files)
  end
end
