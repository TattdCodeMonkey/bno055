defmodule BNO055.DecodeTest do
  use ExUnit.Case

  test "decode_system_status" do
    assert BNO055.decode_system_status(<<0>>) == "Idle"
    assert BNO055.decode_system_status(<<1>>) == "System Error"
    assert BNO055.decode_system_status(<<2>>) == "Initializing Peripherals"
    assert BNO055.decode_system_status(<<3>>) == "System Iniitalization"
    assert BNO055.decode_system_status(<<4>>) == "Executing Self-Test"
    assert BNO055.decode_system_status(<<5>>) == "Sensor fusion algorithm running"
    assert BNO055.decode_system_status(<<6>>) == "System running without fusion algorithms"
    assert BNO055.decode_system_status("T") == "Unknown status: T"
  end

  test "decode_self_test_result" do
    assert BNO055.decode_self_test_result(<<0::size(4), 0xF::size(4)>>) == %{
      mcu: "Pass",
      gyro: "Pass",
      mag: "Pass",
      accel: "Pass"
    }
    assert BNO055.decode_self_test_result(<<0::size(8)>>) == %{
      mcu: "Fail",
      gyro: "Fail",
      mag: "Fail",
      accel: "Fail"
    }
    assert BNO055.decode_self_test_result(<<0::size(4), 0x1::size(4)>>) == %{
      mcu: "Fail",
      gyro: "Fail",
      mag: "Fail",
      accel: "Pass"
    }
    assert BNO055.decode_self_test_result(<<0::size(4), 0x2::size(4)>>) == %{
      mcu: "Fail",
      gyro: "Fail",
      mag: "Pass",
      accel: "Fail"
    }
    assert BNO055.decode_self_test_result(<<0::size(4), 0x8::size(4)>>) == %{
      mcu: "Pass",
      gyro: "Fail",
      mag: "Fail",
      accel: "Fail"
    }
  end

  test "decode_system_error_data" do
    assert BNO055.decode_system_error_data(<<0>>) == "No error"
    assert BNO055.decode_system_error_data(<<1>>) == "Peripheral initialization error"

    assert BNO055.decode_system_error_data(<<2>>) == "System initialization error"
    assert BNO055.decode_system_error_data(<<3>>) == "Self test result failed"
    assert BNO055.decode_system_error_data(<<4>>) == "Register map value out of range"
    assert BNO055.decode_system_error_data(<<5>>) == "Register map address out of range"
    assert BNO055.decode_system_error_data(<<6>>) == "Register map write error"
    assert BNO055.decode_system_error_data(<<7>>) == "BNO low power mode not available for selected operation mode"
    assert BNO055.decode_system_error_data(<<8>>) == "Accelerometer power mode not available"
    assert BNO055.decode_system_error_data(<<9>>) == "Fusion algorithm configuration error"
    assert BNO055.decode_system_error_data(<<10>>) == "Sensor configuration error"
    assert BNO055.decode_system_error_data(<<0xFFFF>>) == "Unknown system error value: #{<<0xFFFF>>}"
  end

  test "decode_revision_info" do
    assert BNO055.decode_revision_info(<<0xA1, 0xB0, 0xC0, 0xF0F0::size(16), 0x10>>) == %{
      accel: 0xA1,
      mag: 0xB0,
      gyro: 0xC0,
      bl: 0x10,
      sw: 0xF0F0,
    }
  end

  test "decode_calibration_status" do
    assert BNO055.decode_calibration_status(<<0xFF>>) == %{
      system: :fully_calibrated,
      gyro: :fully_calibrated,
      accel: :fully_calibrated,
      mag: :fully_calibrated,
    }
    assert BNO055.decode_calibration_status(<<0x00>>) == %{
      system: :not_calibrated,
      gyro: :not_calibrated,
      accel: :not_calibrated,
      mag: :not_calibrated,
    }
    assert BNO055.decode_calibration_status(<<0x03>>) == %{
      system: :not_calibrated,
      gyro: :not_calibrated,
      accel: :not_calibrated,
      mag: :fully_calibrated,
    }
    assert BNO055.decode_calibration_status(<<0x0C>>) == %{
      system: :not_calibrated,
      gyro: :not_calibrated,
      accel: :fully_calibrated,
      mag: :not_calibrated,
    }
    assert BNO055.decode_calibration_status(<<0x30>>) == %{
      system: :not_calibrated,
      gyro: :fully_calibrated,
      accel: :not_calibrated,
      mag: :not_calibrated,
    }
  end

  test "decode_calibration" do
    data = <<
     -100 :: size(16)-signed-little,
     111 :: size(16)-signed-little,
     1000 :: size(16)-signed-little,
     200 :: size(16)-signed-little,
     -222 :: size(16)-signed-little,
     2020 :: size(16)-signed-little,
     -333 :: size(16)-signed-little,
     333 :: size(16)-signed-little,
     3 :: size(16)-signed-little,
     110 :: size(16)-signed-little,
     -200 :: size(16)-signed-little,
    >>

    assert BNO055.decode_calibration(data) == %{
      accel: %{
        x: -100,
        y: 111,
        z: 1000,
        radius: 110,
      },
      mag: %{
        x: 200,
        y: -222,
        z: 2020,
        radius: -200,
      },
      gyro: %{
        x: -333,
        y: 333,
        z: 3,
      },
    }
  end

  test "decode_axis_mapping" do
    data = <<
      0 :: size(2),
      2 :: size(2),
      1 :: size(2),
      0 :: size(2),
      0 :: size(5),
      0 :: size(1),
      1 :: size(1),
      0 :: size(1),
    >>
    assert BNO055.decode_axis_mapping(data) == %{
      x_axis: :x_axis,
      y_axis: :y_axis,
      z_axis: :z_axis,
      x_sign: :positive,
      y_sign: :negative,
      z_sign: :positive,
    }

    data = <<
      0 :: size(2),
      0 :: size(2),
      2 :: size(2),
      1 :: size(2),
      0 :: size(5),
      1 :: size(1),
      0 :: size(1),
      1 :: size(1),
    >>
    assert BNO055.decode_axis_mapping(data) == %{
      x_axis: :y_axis,
      y_axis: :z_axis,
      z_axis: :x_axis,
      x_sign: :negative,
      y_sign: :positive,
      z_sign: :negative,
    }
  end

  test "decode_euler_reading" do
    data = <<
      1460 :: size(16)-signed-little,
      -1765 :: size(16)-signed-little,
      164 :: size(16)-signed-little,
    >>
    assert BNO055.decode_euler_reading(data) == %{
      heading: 91.25,
      roll: -110.3125,
      pitch: 10.25,
    }

    data = <<
      1460 :: size(16)-signed-little,
      -1765 :: size(16)-signed-little,
      164 :: size(16)-signed-little,
    >>
    assert BNO055.decode_euler_reading(data, :degrees) == %{
      heading: 91.25,
      roll: -110.3125,
      pitch: 10.25,
    }

    data = <<
      -2826 :: size(16)-signed-little,
      1413 :: size(16)-signed-little,
      900 :: size(16)-signed-little,
    >>
    assert BNO055.decode_euler_reading(data, :radians) == %{
      heading: -3.14,
      roll: 1.57,
      pitch: 1.0,
    }

    assert BNO055.decode_euler_reading(<<>>) == :no_data 
  end

  test "decode_magnetometer_reading" do
    assert BNO055.decode_magnetometer_reading(<<>>) == :no_data

    assert BNO055.decode_magnetometer_reading(<<
      1832 :: size(16)-signed-little,
      -3364 :: size(16)-signed-little,
      256 :: size(16)-signed-little,
    >>) == %{
      x: 114.5,
      y: -210.25,
      z: 16,
    }
  end
end