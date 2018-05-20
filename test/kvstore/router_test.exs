defmodule KVstore.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias KVstore.Router
  alias KVstore.Storage

  @opts Router.init([])

  setup do
    Storage.clear()
    on_exit fn -> Storage.clear() end
    :ok
  end

  test "get / send welcome message" do
    conn =
      conn(:get, "/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "get /storage return list of values" do
    conn =
      conn(:get, "/storage", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Storage list:\n\n"
  end

  test "get /storage/key return existing pair" do
    key = "new_key"
    KVstore.create({key, "some_value"})
    conn =
      conn(:get, "/storage/#{key}", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Requested pair\n\n\t#{key}\t\t\tsome_value\n"
  end

  test "get /storage/key return error when pair not exist" do
    conn =
      conn(:get, "/storage/some_key", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 400
    assert conn.resp_body == "Wrong request!\nReason: not_found\nTry again!"
  end

  test "post /storage/key/value creates new pair" do
    key = "new_key"
    value = "new_value"
    conn =
      conn(:post, "/storage/#{key}/#{value}", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Requested pair\n\n\t#{key}\t\t\t#{value}\n"

    assert KVstore.get(key) == {:ok, {:new_key, "new_value"}}
  end

  test "post /storage/key/value error when pair exist" do
    key = "new_key"
    value = "new_value"
    KVstore.create({key, value})
    conn =
      conn(:post, "/storage/#{key}/#{value}", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 400
    assert conn.resp_body =="Wrong request!\nReason: record_already_exist\nTry again!"
  end

  test "put /storage/key update existing pair" do
    key = "new_key"
    value = "value"
    KVstore.create({key, value})
    new_value ="new_value"
    conn =
      conn(:put, "/storage/#{key}/#{new_value}", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Requested pair\n\n\t#{key}\t\t\t#{new_value}\n"

    assert KVstore.get(key) == {:ok, {:new_key, "new_value"}}
  end

  test "put /storage/key error when pair not exist" do
    key = "new_key"
    value = "value"
    conn =
      conn(:put, "/storage/#{key}/#{value}", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 400
    assert conn.resp_body =="Wrong request!\nReason: not_found\nTry again!"
  end

  test "delete /storage/key delete existing pair" do
    key = "new_key"
    value = "value"
    KVstore.create({key, value})
    conn =
      conn(:delete, "/storage/#{key}", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Storage list:\n\n"

    assert KVstore.get(key) == {:error, :not_found}
  end

  test "delete /storage/key error when pair not exist" do
    key = "new_key"
    value = "value"
    conn =
      conn(:delete, "/storage/#{key}", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 400
    assert conn.resp_body =="Wrong request!\nReason: not_found\nTry again!"
  end

  test "delete /storage clear the storage" do
    KVstore.create({"key1", "value1"})
    KVstore.create({"key2", "value2"})
    KVstore.create({"key3", "value3"})
    conn =
      conn(:delete, "/storage", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Storage list:\n\n"

    assert KVstore.list() == {:ok, []}
  end
end
