defmodule BNO055.ConfigurationTest do
  use ExUnit.Case

  test "process_names" do
    :application.set_env(:bno055, :names, "test")

    assert BNO055.Configuration.process_names == "test"
  end

  test "sensors" do
    :application.set_env(:bno055, :sensors, "test")

    assert BNO055.Configuration.sensors == "test"
  end

  test "validate_sensors - happy path 1" do
    cfg = [
      %{
        name: "test",
        i2c: "1",
        gproc: "prop"
      }
    ]
    assert BNO055.Configuration.validate_sensors(cfg) == :ok
  end

  test "validate_sensors - happy path 2" do
    cfg = [
      %{
        name: "test",
        i2c: "1",
        gproc: "prop"
      },
      %{
        name: "test2",
        i2c: "2",
        gproc: "prop2"
      }
    ]
    assert BNO055.Configuration.validate_sensors(cfg) == :ok
  end

  test "validate_sensors - nil" do
    assert BNO055.Configuration.validate_sensors(nil) == {:error, "No sensors defined in config"}
  end

  test "validate_sensors - []" do
    assert BNO055.Configuration.validate_sensors([]) == {:error, "At least one sensor should be defined in the config"}
  end

  test "validate_sensors - invalid" do
    cfg = "not a valid sensor config"
    assert BNO055.Configuration.validate_sensors(cfg) == {:error, "Expected a list of maps for sensor config and received #{inspect cfg} instead"}
  end

  test "validate_sensors - invalid sensor" do
    sn = :not_a_map
    assert BNO055.Configuration.validate_sensors([sn]) == {:error, ["Expected sensor config to be a map, instead received #{inspect sn}"]}
  end

  test "validate_sensors - missing name" do
    sensor = %{
      i2c: "1",
      gproc: "111"
    }

    assert BNO055.Configuration.validate_sensors([sensor]) == {:error, ["#{inspect sensor}: expected to sensor config to have a name key containing a string value"]}
  end

  test "validate_sensors - missing i2c" do
    sensor = %{
      name: "test",
      gproc: "111"
    }

    assert BNO055.Configuration.validate_sensors([sensor]) == {:error, ["#{inspect sensor}: expected to sensor config to have an i2c key containing a string value"]}
  end

  test "validate_sensors - missing gproc" do
    sensor = %{
      name: "test",
      i2c: "111"
    }

    assert BNO055.Configuration.validate_sensors([sensor]) == {:error, ["#{inspect sensor}: expected to sensor config to have a gproc key containing a string value"]}
  end

  test "validate_sensors - missing two keys" do
    sensor = %{
      name: "test"
    }

    assert BNO055.Configuration.validate_sensors([sensor]) == {:error, [
      "#{inspect sensor}: expected to sensor config to have an i2c key containing a string value",
      "#{inspect sensor}: expected to sensor config to have a gproc key containing a string value"
    ]}
  end

  test "validate_sensors - one sensor missing gproc" do
    sensor = %{
      name: "test",
      i2c: "111"
    }

    good_sensor = %{
      name: "test2",
      i2c: "2",
      gproc: "prop2"
    }

    assert BNO055.Configuration.validate_sensors([good_sensor, sensor]) == {:error, ["#{inspect sensor}: expected to sensor config to have a gproc key containing a string value"]}
  end

  test "validate_sensors - two bad sensor configs" do
    sensor = %{
      name: "test",
      i2c: "111"
    }

    sensor2 = %{
      name: "test2",
      i2c: "2",
    }

    assert BNO055.Configuration.validate_sensors([sensor, sensor2]) == {:error, [
      "#{inspect sensor}: expected to sensor config to have a gproc key containing a string value",
      "#{inspect sensor2}: expected to sensor config to have a gproc key containing a string value"
    ]}
  end
end
