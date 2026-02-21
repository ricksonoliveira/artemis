defmodule Artemis.Repo do
  use Ecto.Repo,
    otp_app: :artemis,
    adapter: Ecto.Adapters.Postgres
end
