defmodule BNO055.SensorSupervisor do
  use Supervisor

  def start_link(sensor) do
    id = String.to_atom(sensor.name <> "_sup")
    Supervisor.start_link(__MODULE__, [sensor: sensor, name: id], [id: id])
  end

  def init(opts) do
    sensor = Keyword.get(opts, :sensor)
    name = Keyword.get(opts, :name)

    sensor
    |> children
    |> supervise([strategy: :one_for_one, name: name])
  end

  defp children(sensor) do
    state_name = String.to_atom("bno055_" <> sensor.name <> "_state")
    driver_name = String.to_atom("bno055_" <> sensor.name <> "_driver")
    {bus_name, bus_mods} = load_bus_mods(sensor)

    [
      Supervisor.Spec.worker(
        BNO055.Sensor,
        [
          %BNO055.Sensor.State{
            sensor_config: sensor,
            state_name: state_name,
            bus_name: bus_name,
          },
          [name: driver_name]
        ],
        [id: driver_name]
      )
    ] ++ bus_mods
  end

  defp load_bus_mods(sensor) do
    case Code.ensure_loaded?(I2c) do
      true ->
        bus_name = String.to_atom("bno055_" <> sensor.name <> "_busa")
        mods = [
          Supervisor.Spec.worker(
            I2c,
            [sensor.i2c, 0x28, [name: bus_name]],
            [id: bus_name]
          )
        ]
        {bus_name, mods}
      false -> {nil, []} #TODO: Load mock i2c for tests and non-*nix dev ?
    end
  end
end
