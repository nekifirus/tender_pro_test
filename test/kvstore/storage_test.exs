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
    Storage.insert({key, value})

    :dets.open_file(@file_name, [type: :set])
    assert [{_key, _value, _ttl}] = :dets.lookup(@file_name, key)
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

  test "store kill time with pair" do
    ttl = Application.get_env(:kvstore, :ttl)
    time_now = :erlang.system_time(:seconds)
    key = "key"
    value = "value"

    assert Storage.insert({key, value}) == {key, value, time_now + ttl}
  end

  test "kill pair when time over" do
    ttl = Application.get_env(:kvstore, :ttl)
    time_now = :erlang.system_time(:seconds)
    kill_time = time_now + ttl
    key = "key"
    value = "value"
    :dets.open_file(@file_name, [type: :set])

    assert Storage.insert({key, value}) == {key, value, time_now + ttl}
    assert :ets.lookup(@table_name, key) == [{key, value, kill_time}]
    assert :dets.lookup(@file_name, key) == [{key, value, kill_time}]

    :timer.sleep(ttl * 1000)
    assert :ets.lookup(@table_name, key) == []
    assert :dets.lookup(@file_name, key) == []
    :dets.close(@file_name)
  end
end
