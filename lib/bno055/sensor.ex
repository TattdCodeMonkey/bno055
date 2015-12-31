defmodule BNO055.Sensor do
  use GenServer

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    {:ok, args}
  end
end
