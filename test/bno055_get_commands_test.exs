defmodule BNO055.GetCommandsTest do
    use ExUnit.Case

    test "get_chip_address" do
        assert BNO055.get_chip_address() == {0, 1}
    end

    test "get_system_status" do
        assert BNO055.get_system_status() == {0x39, 1}
    end

    test "get_self_test_result" do
        assert BNO055.get_self_test_result() == {0x36, 1}
    end

    test "get_system_error_data" do
        assert BNO055.get_system_error_data() == {0x3A, 1}
    end

    test "get_revision_info" do
        assert BNO055.get_revision_info() == {0x01, 6}
    end

    test "get_calibration_status" do
        assert BNO055.get_calibration_status() == {0x35, 1}
    end

    test "get_calibration" do
        assert BNO055.get_calibration() == {0x55, 22}
    end

    test "get_axis_mapping" do
        assert BNO055.get_axis_mapping() == {0x41, 2}
    end

    test "get_euler_reading" do
        assert BNO055.get_euler_reading() == {0x1A, 6}
    end

    test "get_magnetometer_reading" do
        assert BNO055.get_magnetometer_reading() == {0x0E, 6}
    end

    test "get_gyroscope_reading" do
        assert BNO055.get_gyroscope_reading() == {0x14, 6}
    end

    test "get_accelerometer_reading" do
        assert BNO055.get_accelerometer_reading() == {0x08, 6}
    end

    test "get_linear_acceleration_reading" do
        assert BNO055.get_linear_acceleration_reading() == {0x28, 6}
    end

    test "get_gravity_reading" do
        assert BNO055.get_gravity_reading() == {0x2E, 6}
    end

    test "get_quaternion_reading" do
        assert BNO055.get_quaternion_reading() == {0x20, 8}
    end

    test "get_temperature_reading" do
        assert BNO055.get_temperature_reading() == {0x34, 1}
    end
end