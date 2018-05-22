defmodule KVstore.Test do
  @moduledoc """
  Module for KVstore tests
  """
  use ExUnit.Case, async: false

  alias KVstore.Storage

  @table_name Application.get_env(:kvstore, :table_name)

  setup do
    Storage.clear()
    on_exit fn -> Storage.clear() end
    :ok
  end

  test "list/0 return all keys from table" do
    Storage.insert({:test_key, :test_value})

    assert KVstore.list() == {:ok, [test_key: :test_value]}

  end

  test "create/1 creates new record in table" do
    new_key = "new_key"
    new_value = "new_value"
    assert {:ok, {_new_key, _new_value}} = KVstore.create({new_key, new_value})

    assert [{_new_key, _new_value, _}] = :ets.lookup(@table_name, new_key)

    assert KVstore.create({new_key, new_value}) == {:error, :record_already_exist}
  end

  test "get/1 return {key, value} when exist and error when not exist" do
    Storage.insert({"existed_key", "some_value"})

    assert KVstore.get("existed_key") == {:ok, {"existed_key", "some_value"}}
    assert KVstore.get("not_existed_key") == {:error, :not_found}
  end

  test "update/1 existing record or error" do
    Storage.insert({"existed_key", "some_value"})

    assert KVstore.update({"existed_key", "new_value"}) == {:ok, {"existed_key", "new_value"}}
    assert [{"existed_key", "new_value", _}] = :ets.lookup(@table_name, "existed_key")
    assert KVstore.update({"not_existed_key", "another value"}) == {:error, :not_found}
  end

  test "delete/1 delete record or return error" do
    Storage.insert({"existed_key", "some_value"})

    assert KVstore.delete("existed_key") == {:ok, []}
    assert :ets.lookup(@table_name, "existed_key") == []
    assert KVstore.update({"not_existed_key", "another value"}) == {:error, :not_found}
  end

  test "delete_all/0 clear the table" do
    Storage.insert({:existed_key, "some_value"})
    Storage.insert({:existed_key2, "some_value"})

    assert @table_name |> :ets.tab2list |> length == 2

    assert KVstore.delete_all() == {:ok, []}

    assert @table_name |> :ets.tab2list |> length == 0
  end
end
