defmodule BNO055.Configuration do
  def process_names, do: Application.get_env(:bno055, :names, %{supervisor: :bno055sup})
  def sensors, do: Application.get_env(:bno055, :sensors)

  def validate_sensors(nil), do: {:error, "No sensors defined in config"}
  def validate_sensors([]), do: {:error, "At least one sensor should be defined in the config"}
  def validate_sensors(cfg) when is_list(cfg) do
    cfg
    |> Enum.reduce([], &validate_sensor/2)
    |> Enum.reduce(:ok, &combine_sensor_validations/2)
  end
  def validate_sensors(cfg), do: {:error, "Expected a list of maps for sensor config and received #{inspect cfg} instead"}

  defp validate_sensor(%{} = sensor, errors) do
    case sensor do
      %{name: n} when is_binary(n) -> :ok
      _ ->
        errors = errors ++ ["#{inspect sensor}: expected to sensor config to have a name key containing a string value"]
        :ok
    end

    case sensor do
      %{i2c: i} when is_binary(i) -> :ok
      _ ->
        errors = errors ++ ["#{inspect sensor}: expected to sensor config to have an i2c key containing a string value"]
        :ok
    end

    case sensor do
      %{gproc: g} when is_binary(g) -> :ok
      _ ->
        errors = errors ++ ["#{inspect sensor}: expected to sensor config to have a gproc key containing a string value"]
        :ok
    end

    errors
  end
  defp validate_sensor(cfg, errors) do
    errors ++ ["Expected sensor config to be a map, instead received #{inspect cfg}"]
  end

  defp combine_sensor_validations([], res), do: res
  defp combine_sensor_validations(error, :ok), do: {:error, [error]}
  defp combine_sensor_validations(error, {:error, prev_errs}), do: {:error, prev_errs ++ [error]}

end
