defmodule KVstore.StorageTest do
  use ExUnit.Case, async: false

  alias KVstore.Storage

  @table_name Application.get_env(:kvstore, :table_name)
  @file_name Application.get_env(:kvstore, :file_name)

  setup do
    Storage.clear()
    on_exit fn -> Storage.clear() end
    :ok
  end

  test "create ets table when start" do
    assert [
      read_concurrency: true,
      write_concurrency: false,
      compressed: false,
      memory: _,
      owner: _,
      heir: :none,
      name: @table_name,
      size: _,
      node: _,
      named_table: true,
      type: :set,
      keypos: _,
      protection: :protected
    ] = :ets.info(@table_name)
  end

  test "sincronize ets and dets at start" do
    :dets.open_file(@file_name, [type: :set])
    assert :ets.info(@table_name)[:size] == :dets.info(@file_name)[:size]
    :dets.close(@file_name)
  end

  test "store table contents to dets" do
    key = :test_key
    value = :test_value
    assert Storage.insert({key, value}) == {key, value}

    :dets.open_file(@file_name, [type: :set])
    assert :dets.lookup(@file_name, key) == [{key, value}]
    :dets.close(@file_name)
  end

  test "clear table" do
    Storage.insert({:test_key, :test_value})
    assert :ets.info(@table_name)[:size] != 0
    assert Storage.clear() == []
    assert :ets.info(@table_name)[:size] == 0

    :dets.open_file(@file_name, [type: :set])
    assert :dets.info(@file_name)[:size] == 0
    :dets.close(@file_name)
  end
end
