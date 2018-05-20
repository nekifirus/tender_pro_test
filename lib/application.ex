defmodule KVstore.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    port = Application.get_env(:kvstore, :kv_port)
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, KVstore.Router, [], port: port),
      {KVstore.Storage, []},
    ]

    Logger.info("Cowboy started at port #{port}")
    opts = [strategy: :one_for_one, name: KVstore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
