defmodule BNO055.SetCommandsTest do
  use ExUnit.Case
  
  test "set_mode" do
    assert BNO055.set_mode(:config) == {0x3d, <<0x00>>}
    assert BNO055.set_mode(:acconly) == {0x3d, <<0x01>>}
    assert BNO055.set_mode(:magonly) == {0x3d, <<0x02>>}
    assert BNO055.set_mode(:gyroonly) == {0x3d, <<0x03>>}
    assert BNO055.set_mode(:accmag) == {0x3d, <<0x04>>}
    assert BNO055.set_mode(:accgyro) == {0x3d, <<0x05>>}
    assert BNO055.set_mode(:maggyro) == {0x3d, <<0x06>>}
    assert BNO055.set_mode(:amg) == {0x3d, <<0x07>>}
    assert BNO055.set_mode(:imu) == {0x3d, <<0x08>>}
    assert BNO055.set_mode(:compass) == {0x3d, <<0x09>>}
    assert BNO055.set_mode(:m4g) == {0x3d, <<0x0A>>}
    assert BNO055.set_mode(:ndof_fmc_off) == {0x3d, <<0x0B>>}
    assert BNO055.set_mode(:ndof) == {0x3d, <<0x0C>>}
    
    assert_raise ArgumentError, fn ->
      BNO055.set_mode(:error)
    end
  end

  test "set_external_crystal" do
    assert BNO055.set_external_crystal(true) == {0x3f, <<0x80>>}
    assert BNO055.set_external_crystal(false) == {0x3f, <<0x00>>}
  end

  test "set_calibration" do
    input = <<
      0 :: size(176) # 22 bytes * 8 bits per byte
    >>
    assert BNO055.set_calibration(input) == {0x55, input}

    calibration = %{
      accel: %{
        x: 0,
        y: 0,
        z: 0,
        radius: 0
      },
      mag: %{
        x: 0,
        y: 0,
        z: 0,
        radius: 0
      },
      gyro: %{
        x: 0,
        y: 0,
        z: 0
      }
    }
    assert BNO055.set_calibration(calibration) == {0x55, input}

    assert_raise FunctionClauseError, fn ->
      BNO055.set_calibration(<<0,1>>)
    end
  end

  test "set_power_mode" do
    assert BNO055.set_power_mode(:normal) == {0x3e, <<0x00>>}
    assert BNO055.set_power_mode(:lowpower) == {0x3e, <<0x01>>}
    assert BNO055.set_power_mode(:suspend) == {0x3e, <<0x02>>}

    assert_raise ArgumentError, fn ->
      BNO055.set_power_mode(:other)
    end
  end

  test "reset" do
    assert BNO055.reset() == {0x3f, <<0x20>>}
  end

  test "reset_system_trigger" do
    assert BNO055.reset_system_trigger() == {0x3f, <<0x00>>}
  end

  test "set_page" do
    assert BNO055.set_page(0) == {0x07, <<0x00>>}
    assert BNO055.set_page(1) == {0x07, <<0x01>>}

    assert_raise ArgumentError, fn ->
      BNO055.set_page(2)
    end
  end

  test "set_output_units" do
    assert BNO055.set_output_units(
      :windows,
      :celsius,
      :degrees,
      :dps,
      :ms2
    ) == {0x3b, <<0>>}
    assert BNO055.set_output_units(
      :android,
      :fahrenheit,
      :radians,
      :rps,
      :mg
    ) == {0x3b, <<
      1 :: size(1),
      0 :: size(2),
      1 :: size(1),
      0 :: size(1),
      1 :: size(1),
      1 :: size(1),
      1 :: size(1)
    >>}

    # Invalid values
    assert_raise ArgumentError, fn ->
      BNO055.set_output_units(
        :ios,
        :fahrenheit,
        :radians,
        :rps,
        :mg
      )
    end
    assert_raise ArgumentError, fn ->
      BNO055.set_output_units(
        :android,
        :kelvin,
        :radians,
        :rps,
        :mg
      )
    end
    assert_raise ArgumentError, fn ->
      BNO055.set_output_units(
        :android,
        :fahrenheit,
        :decimal,
        :rps,
        :mg
      )
    end
    assert_raise ArgumentError, fn ->
      BNO055.set_output_units(
        :android,
        :fahrenheit,
        :radians,
        :ack,
        :mg
      )
    end
    assert_raise ArgumentError, fn ->
      BNO055.set_output_units(
        :android,
        :fahrenheit,
        :radians,
        :rps,
        :bar
      )
    end
  end

  test "set_axis_mapping" do
    assert BNO055.set_axis_mapping(
      :z_axis,
      :x_axis,
      :y_axis,
      :positive,
      :negative,
      :positive
    ) == {0x41, <<
      0::size(2), # Blank
      1::size(2), # Z Axis mapping
      0::size(2), # Y Axis mapping
      2::size(2), # X Axis mapping
      0::size(5), # Blank
      0::size(1), # X-axis sign
      1::size(1), # Y-axis sign
      0::size(1)  # Z-axis sign
    >>}

    assert BNO055.set_axis_mapping(      
      :x_axis,
      :z_axis,
      :y_axis,
      :negative,
      :negative,
      :negative
    ) == {0x41, <<
      0::size(2), # Blank
      1::size(2), # Z Axis mapping
      2::size(2), # Y Axis mapping
      0::size(2), # X Axis mapping
      0::size(5), # Blank
      1::size(1), # X-axis sign
      1::size(1), # Y-axis sign
      1::size(1)  # Z-axis sign
    >>}

    assert BNO055.set_axis_mapping(      
      :x_axis,
      :y_axis,
      :z_axis,
      :positive,
      :positive,
      :positive
    ) == {0x41, <<
      0::size(2), # Blank
      2::size(2), # Z Axis mapping
      1::size(2), # Y Axis mapping
      0::size(2), # X Axis mapping
      0::size(5), # Blank
      0::size(1), # X-axis sign
      0::size(1), # Y-axis sign
      0::size(1)  # Z-axis sign
    >>}

    # Invalid parameters
    assert_raise ArgumentError, fn ->
      BNO055.set_axis_mapping(:x_axis, :x_axis, :z_axis, :positive, :positive, :positive)
    end
    assert_raise ArgumentError, fn ->
      BNO055.set_axis_mapping(:x_axis, :y_axis, :x_axis, :positive, :positive, :positive)
    end
    assert_raise ArgumentError, fn ->
      BNO055.set_axis_mapping(:x_axis, :z_axis, :z_axis, :positive, :positive, :positive)
    end
    assert_raise ArgumentError, fn ->
      BNO055.set_axis_mapping(:x_axis, :y_axis, :z_axis, :bad, :negative, :positive)
    end
    assert_raise ArgumentError, fn ->
      BNO055.set_axis_mapping(:x_axis, :y_axis, :z_axis, :positive, :bad, :positive)
    end
    assert_raise ArgumentError, fn ->
      BNO055.set_axis_mapping(:x_axis, :y_axis, :z_axis, :positive, :negative, :bad)
    end
  end
end