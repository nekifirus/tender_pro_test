defmodule KVstore.Storage do
  @moduledoc """
  Module for functions to work with storage
  """
  use GenServer

  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc """
  Update or insert `value` for `key` in table and return {key, value}
  """
  @spec insert(tuple()) :: tuple()
  def insert(data), do: GenServer.call(__MODULE__, {:insert, data})

  @doc """
  Delete {key, value} from table
  """
  @spec delete(binary) :: [tuple]
  def delete(key), do: GenServer.call(__MODULE__, {:delete, key})

  @doc """
  Clear table
  """
  @spec clear() :: []
  def clear(), do: GenServer.call(__MODULE__, :clear)

  # Callbacks
  @doc """
  Init function. If dets table exist - create ets and insert all values from dets. Else - create clear ets and dets tables
  """

  def init(:ok) do
    ets_table = :ets.new(table_name(), [:set, :protected, :named_table, read_concurrency: true])
    {:ok, dets_table} = :dets.open_file(file_name(), [type: :set])

    case :dets.info(dets_table)[:size] do
      0 ->
        Logger.info "Created new tables"

      count ->
        Logger.info "Reading #{count} values from dets"
        :ets.from_dets(ets_table, dets_table)
    end

    :dets.close(dets_table)

    schedule_work()

    {:ok, %{ets_table: ets_table, dets_table: dets_table}}
  end

  @doc """
  When GenServer terminating - store all values in dets
  """
  def terminate(_reason, state) do
    :dets.open_file(state.dets_table, [type: :set])
    :ets.to_dets(state.ets_table, state.dets_table)
    :dets.close(state.dets_table)
    :ets.delete(state.ets_table)
  end

  @doc """
  On insert store changes in dets
  """
  def handle_call({:insert, {key, value}}, _from, state) do
    ttl = :erlang.system_time(:seconds) + Application.get_env(:kvstore, :ttl)
    :ets.insert(state.ets_table, {key, value, ttl})

    :dets.open_file(state.dets_table, [type: :set])
    :ets.to_dets(state.ets_table, state.dets_table)
    :dets.close(state.dets_table)

    {:reply, {key, value, ttl}, state}
  end

  @doc """
  Deletes record from table
  """
  def handle_call({:delete, key}, _from, state) do
    :ets.delete(state.ets_table, key)

    :dets.open_file(state.dets_table, [type: :set])
    :dets.delete(state.dets_table, key)
    :dets.close(state.dets_table)

    {:reply, :ets.tab2list(state.ets_table), state}
  end
  @doc """
  Clear the table
  """
  def handle_call(:clear, _from, state) do
    :ets.delete_all_objects(state.ets_table)

    :dets.open_file(state.dets_table, [type: :set])
    :dets.delete_all_objects(state.dets_table)
    :dets.close(state.dets_table)

    {:reply, :ets.tab2list(state.ets_table), state}
  end

  def handle_call(_request, _from, state), do: {:reply, state, state}
  def handle_cast(_request, state), do: {:reply, state}

  def handle_info(:work, state) do
    time_now = :erlang.system_time(:seconds)
    query = [{{:"$1", :"$2", :"$3"}, [{:"=<", :"$3", {:const, time_now}}], [:"$1"]}]

    state.ets_table
    |> :ets.select(query)
    |> Enum.each(fn x ->
      :ets.delete(state.ets_table, x)
      :dets.delete(state.dets_table, x)
    end)

    schedule_work()
    {:noreply, state}
  end

  defp table_name(), do: Application.get_env(:kvstore, :table_name)
  defp file_name(), do: Application.get_env(:kvstore, :file_name)

  defp schedule_work() do
    Process.send_after(self(), :work, 1000)
  end
end
