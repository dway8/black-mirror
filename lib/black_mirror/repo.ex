defmodule BlackMirror.Repo do
  use Ecto.Repo,
    otp_app: :black_mirror,
    adapter: Ecto.Adapters.Postgres
end
