defmodule ExAthena.Listener.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExAthena.Listener.Registry
    ]

    opts = [strategy: :one_for_one, name: ExAthena.Listener.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
