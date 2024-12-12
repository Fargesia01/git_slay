defmodule GitSlay.Repo do
  use Ecto.Repo,
    otp_app: :git_slay,
    adapter: Ecto.Adapters.Postgres
end
