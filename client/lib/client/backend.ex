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

  def list_remote_files do
    record = Path.wildcard(@filesPath <> "commit/*")
          |> Enum.filter(&File.regular?(&1))
          |> Enum.reduce(%{}, fn f, acc ->
            [fileName, version] =
              String.split(List.last(String.split(f, "/", parts: :infinity)), @splitChars,
                parts: 2
              )

            Map.update(acc, fileName, [version], fn versions -> [version | versions] end)
          end)
    Application.put_env(:client, :record, record)
    for {file, versions} <- record, into: %{} do
      {file, Enum.max(versions)}
    end
  end

  @doc """
  Returns all the versions of the given file that are saved locally.
  """
  def get_versions(file) do
    try do
      Map.fetch!(Application.get_env(:client, :record), file)
    rescue
      KeyError -> nil
    end
  end

  @doc """
  Returns the data of the given file and version.
  """
  def get_file(file, ver) do
    try do
      File.read!(@filesPath <> "commit/#{file}#{@splitChars}#{ver}")
    rescue
      File.Error -> nil
    end
  end

  def put_in_local(file, ver, data) do
    File.write(@filesPath <> "commit/#{file}#{@splitChars}#{ver}", data)
    File.cp(@filesPath <> "commit/#{file}#{@splitChars}#{ver}", @filesPath <> "user/#{file}")

    record = Application.get_env(:client, :record)
    remote_files = Application.get_env(:client, :remote_files)

    Application.put_env(
      :client,
      :record,
      Map.update(record, file, ver, fn versions ->
        if !Enum.any?(record, fn e -> e == ver end) do
          [ver | versions]
        end
      end)
    )

    Application.put_env(
      :client,
      :remote_files,
      Map.update(remote_files, file, ver, fn version ->
        if String.to_integer(version) < String.to_integer(ver) do
          ver
        end
      end)
    )
  end

  def list_all_files do
    ip = Application.get_env(:client, :server_ip)
    url = "http://#{ip}:5000/api/request-file-list"
    body = ""

    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} -> 
        case Jason.decode(response_body) do
          {:ok, %{"files" => files}} -> 
            IO.puts("Successfully received file list from server: #{inspect(files)}")
            Application.put_env(:client, :remote_files, files)
            files
          {:error, reason} -> 
            IO.puts("Failed to decode JSON response: #{inspect(reason)}")
            %{}
        end
      {:error, %HTTPoison.Error{reason: reason}} -> 
        IO.puts("Failed to request file list from server: #{inspect(reason)}")
        %{}
    end
  end

  def commit(file) do
    remote_files = Application.get_env(:client, :remote_files)
    record = Application.get_env(:client, :file)

    mr_v = String.to_integer(Map.get(remote_files, file, "-1")) + 1

    data =
      try do
        File.read!(@filesPath <> "user/#{file}")
      rescue
        File.Error -> ""
      end

    File.write(@filesPath <> "commit/#{file}#{@splitChars}#{mr_v}", data)

    remote_files = Map.put(remote_files, file, mr_v)
    record = Map.put(record, file, [mr_v | Map.get(record, file)])

    Application.put_env(:client, :remote_files, remote_files)
    Application.put_env(:client, :record, record)
  end

  def send_file_list_to_server(file_list) do
    ip = Application.get_env(:client, :server_ip)
    url = "http://#{ip}:5000/api/send-file-list"
    body = Jason.encode!(%{
      "client_id" => Application.get_env(:client, :client_id),
      "file_list" => file_list
    })

    IO.puts("Sending file list to server: #{inspect(file_list)}")

    HTTPoison.post(url, body, [{"Content-Type", "application/json"}])
  end
end
