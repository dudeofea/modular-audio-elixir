defmodule ModularAudioElixir.Repo do
  use Ecto.Repo,
    otp_app: :modular_audio_elixir,
    adapter: Ecto.Adapters.Postgres
end
