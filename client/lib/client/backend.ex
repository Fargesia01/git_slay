defmodule Client.Backend do
  @moduledoc"""
  Dans ce module se trouve une liste de fonctions du backend
  """

  def list_local_files do
    ["README.md", "project.ex", "notes.txt", "design.png"] 
  end

  def list_all_files do
    ["READMsadfE.md", "project.ex", "notes.txt", "design.png"] 
  end

  def commit(path \\ @filesPath <> "commit/", file) do
    remote_files = Application.get_env(:client, :remote_files)

    rm_v =
      try do
        Map.get!(remote_files, file)
      rescue
        _error -> 0
      end

    data =
      try do
        File.read!(@filesPath <> "user/#{file}")
      rescue
        File.Error -> ""
      end

    File.write!(path <> "#{file}#{@splitChars}#{ver}", data)
  end

  def send_file_list_to_server(file_list) do
    url = "http://192.168.1.11:5000/api/send-file-list"
    body = Jason.encode!(%{
      "client_id" => Application.get_env(:client, :client_id),
      "file_list" => file_list
    })

    HTTPoison.post(url, body, [{"Content-Type", "application/json"}])
  end
end
