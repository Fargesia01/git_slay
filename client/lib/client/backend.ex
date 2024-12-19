defmodule Client.Backend do
  @moduledoc"""
  Dans ce module se trouve une liste de fonctions du backend
  """
  @splitChars "--"
  @filesPath (__ENV__.file |> String.split("lib/") |> hd()) <> "priv/files/"
  @record Path.wildcard(@filesPath <> "commit/*")
          |> Enum.filter(&File.regular?(&1))
          |> Enum.reduce(%{}, fn f, acc ->
            [fileName, version] =
              String.split(List.last(String.split(f, "/", parts: :infinity)), @splitChars,
                parts: 2
              )

            Map.update(acc, fileName, [version], fn versions -> [version | versions] end)
          end)

  def list_local_files() do
    for f <- Path.wildcard(@filesPath <> "user/*"),
        File.regular?(f),
        do: String.split(f, "/", parts: :infinity) |> List.last()
  end

  def list_remote_files() do
    for f <- Path.wildcard(@filesPath <> "commit/*"), File.regular?(f), into: %{} do
      f_name =
        String.split(List.last(String.split(f, "/", parts: :infinity)), @splitChars, parts: 2)
        |> hd()

      mr_ver = Enum.max(Map.get(@record, f_name))

      {f_name, mr_ver}
    end
  end

  def list_all_files do
    url = "http://192.168.1.11:5000/api/request-file-list"
    client_id = Application.get_env(:client, :client_id) || "unknown_client"

    body = Jason.encode!(%{client_id: client_id})

    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} -> 
        IO.puts("Successfully requested file list from server: #{response_body}")
      {:error, %HTTPoison.Error{reason: reason}} -> 
        IO.puts("Failed to request file list from server: #{inspect(reason)}")
    end

     %{
    "README.md" => 7,
    "project.ex" => 9,
    "notes.txt" => 4,
    "design.png" => 10,
    "main.py" => 3,
    "index.html" => 6,
    "style.css" => 2,
    "app.js" => 8,
    "database.sql" => 1,
    "server.rb" => 5,
    "client.go" => 2,
    "utils.java" => 9,
    "long_filename_with_extra_characters_just_to_see_how_it_fits.txt" => 11,
    "another_really_long_filename_to_test_text_wrapping_issues.md" => 15,
    "config.yaml" => 3,
    "environment.env" => 4,
    "package.json" => 7,
    "webpack.config.js" => 5,
    "Dockerfile" => 1,
    "Makefile" => 3,
    "LICENSE" => 2,
    "CONTRIBUTING.md" => 8,
    "AUTHORS" => 6,
    "Changelog.txt" => 5,
    "data.csv" => 9,
    "analytics_report_2024.xlsx" => 10,
    "test_suite.exs" => 7,
    "module_diagram.pptx" => 12,
    "architecture_overview.pdf" => 14,
    "release_notes_v1.2.3.pdf" => 8,
    "sample_data.json" => 3
  }

  end

  def commit(file) do
    remote_files = Application.get_env(:client, :remote_files)
    mr_v = Map.get(remote_files, file, -1) + 1

    data =
      try do
        File.read!(@filesPath <> "user/#{file}")
      rescue
        File.Error -> ""
      end

    File.write(@filesPath <> "commit/#{file}#{@splitChars}#{mr_v}", data)

    remote_files =
      if Map.has_key?(remote_files, file) do
        Map.put(remote_files, file, mr_v)
      else
        Map.put_new(remote_files, file, mr_v)
      end

    Application.put_env(:client, :remote_files, remote_files)
  end

  def send_file_list_to_server(file_list) do
    url = "http://192.168.1.11:5000/api/send-file-list"
    body = Jason.encode!(%{
      "client_id" => Application.get_env(:client, :client_id),
      "file_list" => file_list
    })

    IO.puts("Sending file list to server: #{inspect(file_list)}")

    HTTPoison.post(url, body, [{"Content-Type", "application/json"}])
  end
end
