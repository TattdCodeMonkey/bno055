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
    names = BNO055.Configuration.process_names
    event_mgr = names.eventmgr

    state_name = String.to_atom("bno055_" <> sensor.name <> "_state")
    driver_name = String.to_atom("bno055_" <> sensor.name <> "_driver")
    bus_names = %{
      deva: String.to_atom("bno055_" <> sensor.name <> "_busa"),
      devb: String.to_atom("bno055_" <> sensor.name <> "_busb")
    }

    [
      Supervisor.Spec.worker(
        BNO055.Sensor,
        [
          %{
            state_name: state_name,
            bus_names: bus_names,
            evt_mgr: event_mgr,
            offsets: Map.get(sensor, :offsets, BNO055.Configuration.default_offsets),
            median: Map.get(sensor, :median, BNO055.Configuration.default_median)
          },
          [name: driver_name]
        ],
        [id: driver_name]
      )
    ] ++ bus_modules(sensor, bus_names)
  end



  defp bus_modules(sensor, bus_names) do
    case Code.ensure_loaded?(I2c) do
      true -> [
          Supervisor.Spec.worker(
            I2c,
            [sensor.i2c, 0x28, [name: bus_names.deva]],
            [id: bus_names.deva]
          ),
          Supervisor.Spec.worker(
            I2c,
            [sensor.i2c, 0x29, [name: bus_names.devb]],
            [id: bus_names.devb]
          )
        ]
      false -> [] #TODO: Load mock i2c for tests and non-*nix dev ?
    end
  end
end
