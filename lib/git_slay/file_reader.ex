defmodule GitSlay.FileReader do
  @moduledoc"""
  Ce module lit un fichier txt. Ce module est elixir pure est n'est pas dépendant de réseau ou front.
  """

  @file_path "priv/test.txt"

  def read_file do
    case File.read(@file_path) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, reason}
    end
  end
end
