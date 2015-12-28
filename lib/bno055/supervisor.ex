defmodule BNO055.Supervisor do
  use Supervisor
  require Logger

  def start_link, do: Supervisor.start_link(__MODULE__, [], [])

  def init(_) do
    names = Application.get_env(:bno055, :names)

    Application.get_env(:bno055, :processes)
    |> Enum.map(&get_child/1)
    |> supervise([strategy: :one_for_one, name: names.supervisor])
  end

  defp get_child({:worker, args}) do
    apply(Supervisor.Spec, :worker, args)
  end

  defp get_child({:supervisor, args}) do
    apply(Supervisor.Spec, :supervisor, args)
  end
end
