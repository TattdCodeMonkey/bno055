defmodule BNO055.Configuration do
  def process_names, do: Application.get_env(:bno055, :names)
  def sensors, do: Application.get_env(:bno055, :sensors)

  def default_offsets, do: %{pitch: 0.0, roll: 0.0, heading: 0.0}
  def default_median, do: %{enable: false, samples: 5}
end
