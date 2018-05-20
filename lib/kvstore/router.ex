defmodule KVstore.Router do
  @moduledoc """
  KVstore application router module
  """
  use Plug.Router
  use Plug.ErrorHandler

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, """
    Welcome\n
    This is simple Key Value Storage application\n
    try to request enpoints:\n
    \n
    get /storage - return list of storred values\n
    post /storage/key/value - creates new value\n
    get /storage/key - return stored value or error\n
    put /storage/key/new_value update existing key with new value or return error\n
    delete /storage/key - delete key value pair from storage and return new storage list. If key not exist return error\n
    delete /storage - clear storage and return empty list\n
  """))

  get("/storage", do: (
       with {:ok, list} <- KVstore.list() do
         send_list(conn, list)
       end
  ))

  get("/storage/:key", do: (
    with {:ok, pair} <- KVstore.get(key) do
      send_pair(conn, pair)
    else
      {:error, reason} ->
        send_error(conn, reason)
    end
  ))

  post("/storage/:key/:value", do: (
    with {:ok, pair} <- KVstore.create({key, value}) do
      send_pair(conn, pair)
    else
      {:error, reason} -> send_error(conn, reason)
    end
  ))

  put("/storage/:key/:value", do: (
    with {:ok, pair} <- KVstore.update({key, value}) do
      send_pair(conn, pair)
    else
      {:error, reason} -> send_error(conn, reason)
    end
  ))

  delete("/storage/:key", do: (
    with {:ok, list} <- KVstore.delete(key) do
      send_list(conn, list)
    else
      {:error, reason} -> send_error(conn, reason)
    end
  ))

  delete("/storage", do: (
    with {:ok, list} <- KVstore.delete_all() do
      send_list(conn, list)
    else
      {:error, reason} -> send_error(conn, reason)
    end
  ))

  match(_, do: send_resp(conn, 404, "I don't understand what are you won't to do with me!\n"))

  defp send_list(conn, list) do
    presentation = Enum.reduce(list, "Storage list:\n\n", fn (x, acc) -> acc <> print_pair(x) end)
    send_resp(conn, 200, presentation)
  end

  defp send_pair(conn, pair) do
    presentation = "Requested pair\n\n" <> print_pair(pair)
    send_resp(conn, 200, presentation)
  end

  defp print_pair({key, value}) do
    "\t#{key}\t\t\t#{value}\n"
  end

  defp send_error(conn, reason) do
    send_resp(conn, 400, "Wrong request!\nReason: #{reason}\nTry again!")
  end
end
