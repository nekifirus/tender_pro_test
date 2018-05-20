defmodule KVstore.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {KVstore.Storage, []},
    ]

    opts = [strategy: :one_for_one, name: KVstore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
