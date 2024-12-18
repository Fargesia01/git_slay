defmodule Client.Backend do
  @moduledoc"""
  Dans ce module se trouve une liste de fonctions du backend
  """

  def list_local_files do
    ["READMEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE.md", "project.ex", "notes.txt", "design.png", "slkdjfsld.fsdf", "klsjdf", "sdfsd,fms", "slkdjfslkdjf",
      "README.md", "project.ex", "notes.txt", "design.png", "slkdjfsld.fsdf", "klsjdf", "sdfsd,fms", "slkdjfslkdjf",
      "README.md", "project.ex", "notes.txt", "design.png", "slkdjfsld.fsdf", "klsjdf", "sdfsd,fms", "slkdjfslkdjf",
      "README.md", "project.ex", "notes.txt", "design.png", "slkdjfsld.fsdf", "klsjdf", "sdfsd,fms", "slkdjfslkdjf",
      "README.md", "project.ex", "notes.txt", "design.png", "slkdjfsld.fsdf", "klsjdf", "sdfsd,fms", "slkdjfslkdjf",
      "README.md", "project.ex", "notes.txt", "design.png", "slkdjfsld.fsdf", "klsjdf", "sdfsd,fms", "slkdjfslkdjf",
      "README.md", "project.ex", "notes.txt", "design.png", "slkdjfsld.fsdf", "klsjdf", "sdfsd,fms", "slkdjfslkdjf",
      "README.md", "project.ex", "notes.txt", "design.png", "slkdjfsld.fsdf", "klsjdf", "sdfsd,fms", "slkdjfslkdjf",
      "README.md", "project.ex", "notes.txt", "design.png", "slkdjfsld.fsdf", "klsjdf", "sdfsd,fms", "slkdjfslkdjf",
      "README.md", "project.ex", "notes.txt", "design.png", "slkdjfsld.fsdf", "klsjdf", "sdfsd,fms", "slkdjfslkdjf",
    ] 
  end

  def list_all_files do
    ["READMsadfE.md", "project.ex", "notes.txt", "design.png"] 
  end

  def commit(file) do
    remote_files = Application.get_env(:client, :remote_files)
    mr_v = Map.get(remote_files, file, 0)

    data =
      try do
        File.read!(@filesPath <> "user/#{file}")
      rescue
        File.Error -> ""
      end

    File.write(@filesPath <> "commit/#{file}#{@splitChars}#{mr_v}", data)
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
