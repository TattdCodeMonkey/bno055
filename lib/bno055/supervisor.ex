defmodule BNO055.Supervisor do
  use Supervisor
  require Logger

  def start_link, do: Supervisor.start_link(__MODULE__, [], [])

  def init(_) do
    names = BNO055.Configuration.process_names

    get_app_children(names)
    ++ Enum.map(BNO055.Configuration.sensors, &sensor_sup/1)
    |> supervise([strategy: :one_for_one, name: names.supervisor])
  end

  defp get_app_children(names) do
    [
      worker(GenEvent, [[name: names.eventmgr]], [id: names.eventmgr])
    ]
  end

  defp sensor_sup(sensor) do
    supervisor(BNO055.SensorSupervisor, [sensor])
  end
end
