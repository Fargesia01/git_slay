defmodule GitSlayWeb.PageController do
  use GitSlayWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home)
  end

  def read_file(conn, _params) do
    case GitSlay.FileReader.read_file() do
      {:ok, content} -> 
        json(conn, %{content: content})
      {:error, reason} -> 
        json(conn, %{error: "Failed to read file: #{inspect(reason)}"})
    end
  end
end
