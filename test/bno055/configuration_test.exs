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
end
