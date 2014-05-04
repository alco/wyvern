defmodule Wyvern.Cache do
  use GenServer.Behaviour

  def start_link() do
    :gen_server.start_link({:local, __MODULE__}, __MODULE__, [], [])
  end

  def init(_) do
    {:ok, %{}}
  end

  def get(key) do
    :gen_server.call(__MODULE__, {:get, key})
  end

  def put(key, val) do
    :gen_server.call(__MODULE__, {:put, key, val})
  end

  def reset(state) do
    :gen_server.call(__MODULE__, {:reset, state})
  end

  def get_state() do
    :gen_server.call(__MODULE__, :get_state)
  end

  def handle_call({:get, key}, _, map) do
    {:reply, Map.get(map, key), map}
  end

  def handle_call({:put, key, val}, _, map) do
    {:reply, :ok, Map.put(map, key, val)}
  end

  def handle_call({:reset, state}, _, _) do
    {:reply, :ok, state}
  end

  def handle_call(:get_state, _, map) do
    {:reply, map, map}
  end
end
