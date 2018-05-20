defmodule KVstore do
  @moduledoc """
  Main module of KVstore application
  Provide public CRUD functions
  """
  alias KVstore.Storage

  @spec list() :: [any()]
  def list() do
    {:ok, :ets.tab2list(table_name())}
  end


  @spec create(tuple()) :: {:ok, tuple()} | {:error, :already_exist}
  def create({key, value}) do
    case get(key) do
      {:error, :not_found} ->
        atom_key = String.to_atom(key)
        {:ok, Storage.insert({atom_key, value})}

      {:ok, _} ->
        {:error, :record_already_exist}
    end
  end

  @spec get(binary) :: {:ok, tuple} | {:error, :not_found}
  def get(key) do
    atom_key = String.to_atom(key)

    case :ets.lookup(table_name(), atom_key) do
      [] -> {:error, :not_found}
      [{atom_key, value}] -> {:ok, {atom_key, value}}
    end
  end

  @spec update(tuple) :: {:ok, tuple} | {:error, :not_found}
  def update({key, new_value}) do
    with {:ok, {atom_key, _value}} <- get(key),
         {atom_key, updated_value} <- Storage.insert({atom_key, new_value}) do
      {:ok, {atom_key, updated_value}}
    end
  end

  @spec delete(binary) :: {:ok, [tuple]} :: {:error, :not_found}
  def delete(key) do
    with {:ok, {atom_key, _value}} <- get(key),
         new_table <- Storage.delete(atom_key) do
      {:ok, new_table}
    end
  end

  @spec delete_all() :: {:ok, []}
  def delete_all(), do: {:ok, Storage.clear}

  defp table_name(), do: Application.get_env(:kvstore, :table_name)
end
