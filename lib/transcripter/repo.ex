defmodule Transcripter.Repo do
  use Ecto.Repo,
    otp_app: :transcripter,
    adapter: Ecto.Adapters.Postgres
end
