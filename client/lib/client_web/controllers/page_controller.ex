defmodule ClientWeb.PageController do
  use ClientWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end

  def read_file(conn, _params) do
    case Client.FileReader.read_file() do
      {:ok, content} -> 
        json(conn, %{content: content})
      {:error, reason} -> 
        json(conn, %{error: "Failed to read file: #{inspect(reason)}"})
    end
  end
end
