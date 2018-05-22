defmodule KVstore do
  @moduledoc """
  Main module of KVstore application
  Provide public CRUD functions
  """
  alias KVstore.Storage

  @spec list() :: [any()]
  def list() do
    list = table_name() |> :ets.tab2list() |> drop_ttl()
    {:ok, list}
  end


  @spec create(tuple()) :: {:ok, tuple()} | {:error, :already_exist}
  def create({key, value}) do
    case get(key) do
      {:error, :not_found} ->
        {key, value, _ttl} = Storage.insert({key, value})
        {:ok, {key, value}}

      {:ok, _} ->
        {:error, :record_already_exist}
    end
  end

  @spec get(binary) :: {:ok, tuple} | {:error, :not_found}
  def get(key) do
    case :ets.lookup(table_name(), key) do
      [] -> {:error, :not_found}
      [{atom, value, _ttl}] -> {:ok, {key, value}}
    end
  end

  @spec update(tuple) :: {:ok, tuple} | {:error, :not_found}
  def update({key, new_value}) do
    with {:ok, {key, _value}} <- get(key),
         {key, updated_value, _ttl} <- Storage.insert({key, new_value}) do
      {:ok, {key, updated_value}}
    end
  end

  @spec delete(binary) :: {:ok, [tuple]} :: {:error, :not_found}
  def delete(key) do
    with {:ok, {key, _value}} <- get(key),
         new_table <- key |> Storage.delete() |> drop_ttl() do
      {:ok, new_table}
    end
  end

  @spec delete_all() :: {:ok, []}
  def delete_all(), do: {:ok, Storage.clear}

  defp table_name(), do: Application.get_env(:kvstore, :table_name)

  defp drop_ttl([]), do: []
  defp drop_ttl(list) when is_list(list), do: Enum.map(list, fn {key, value, ttl} -> {key, value} end)
end
