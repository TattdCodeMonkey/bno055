defmodule BNO055.SensorState do
  use GenServer

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def update(pid, %{} = value) do
    GenServer.cast(pid, {:update, value})
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def init(:ok) do
    {:ok, Map.new}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_key, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  def handle_call({:update, %{} = value}, _from, state) do
    state = Map.merge(state, value)
    {:reply, state, state}
  end

  def handle_cast({:update, %{} = value}, state) do
    state = Map.merge(state, value)
    {:noreply, state}
  end
end
