defmodule BNO055.Sensor do
  use GenServer

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
  	BNO055.SensorState.init(args.state_name)

    {:ok, args}
  end
end
