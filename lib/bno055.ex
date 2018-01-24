defmodule BNO055 do
  use BNO055.SensorInterface

  @moduledoc """
  This module is used to create commands for interacting with a Bosch BNO055 sensor. This
  module is intended to be an unopinionated collection of functions to created data for
  communicating with the sensor, but does not handle actual communication.

  Set functions return tuple with address and data to be written to that address
  ```elixir
  iex> BNO055.set_mode(:config)
  {0x3D, <<0x00>>}
  ```

  Get functions return tuple with address and number of bytes to read
  ```elixir
  iex> BNO055.get_chip_address
  {0x00, 1}
  ```

  `write` functions take the get or set results and return a binary for writing to the 
  device based on the protocol type

  iex> BNO055.set_mode(:config) |> BNO055.i2c_write_data
  <<0x3D, 0x00>>

  iex> BNO055.set_mode(:config) |> BNO055.serial_write_data
  <<0xAA, 0x00, 0x3D, 0x01, 0x00>>

  Decode functions take the data returned from get functions and returns formatted results
  """

  @type register_address :: 0..0x6A
  @type set_result :: {register_address, binary}
  @type get_result :: {register_address, pos_integer}
  @type operational_modes :: :config | :acconly | :magonly | :gyroonly | :accmag |
    :accgyro | :maggyro | :amg | :imu | :compass | :m4g | :ndof_fmc_off | :ndof

  @type power_mode :: :normal | :lowpower | :suspend
  @type axis_remap :: :x_axis|:y_axis|:z_axis
  @type axis_sign :: :positive | :negative

  @doc """
  Sets the operational mode of the BNO055 sensor.
  
  ## Valid Modes:
   - :config - Used to configure the sensor
  ** Non-fusion modes **
   - :acconly - Only accelerometer sensor on
   - :magonly - Only magnetometer sensor on
   - :gyroonly - Only gyroscope sensor on
   - :accmag - Both accelerometer & magnetometer sensors on
   - :accgyro - Both accelerometer & gyroscope sensors on
   - :maggyro - Both magnetometer & gyroscope sensors on
   - :amg - All three sensors on, but no fusion data generated
  ** Fusion modes **
   - :imu - the relative orientation of the BNO055 in space is calculated from the accelerometer and gyroscope data. The calculation is fast (i.e. high output data rate)
   - :compass - th absolute orientation of the BNO055 is given. (requires calibration. see datasheet)
   - :m4g - Magnet for Gyroscope - similar to IMU, but uses magnetometer to detect rotation
   - :ndof_fmc_off - same as NDOF, but with Fast Magnetometer Calibration turned off
   - :ndof - Fusion mode with 9 degrees of freedom where the fused absolute orientation data is calculate from all three sensors.

  See section 3.3 of the datasheet for more detailed information
  on the operational modes.
  """
  @spec set_mode(operational_modes) :: set_result
  def set_mode(:config), do: {@opr_mode_addr, <<0x00>>}
  def set_mode(:acconly), do: {@opr_mode_addr, <<0x01>>}
  def set_mode(:magonly), do: {@opr_mode_addr, <<0x02>>}
  def set_mode(:gyroonly), do: {@opr_mode_addr, <<0x03>>}
  def set_mode(:accmag), do: {@opr_mode_addr, <<0x04>>}
  def set_mode(:accgyro), do: {@opr_mode_addr, <<0x05>>}
  def set_mode(:maggyro), do: {@opr_mode_addr, <<0x06>>}
  def set_mode(:amg), do: {@opr_mode_addr, <<0x07>>}
  def set_mode(:imu), do: {@opr_mode_addr, <<0x08>>}
  def set_mode(:compass), do: {@opr_mode_addr, <<0x09>>}
  def set_mode(:m4g), do: {@opr_mode_addr, <<0x0A>>}
  def set_mode(:ndof_fmc_off), do: {@opr_mode_addr, <<0x0B>>}
  def set_mode(:ndof), do: {@opr_mode_addr, <<0x0C>>}
  def set_mode(inv_mode), do: raise ArgumentError, "Invalid mode #{inv_mode} given!"

  @doc """
  Sets if an external crystal is attached to the sensor.

  ** Sensor must be in config mode before receiving this command
  """
  @spec set_external_crystal(true|false) :: set_result
  def set_external_crystal(true), do: {@sys_trigger_addr, <<0x80>>}
  def set_external_crystal(false), do: {@sys_trigger_addr, <<0x00>>}

  @doc """
  Set the sensor calibration offsets by sending previously generated
  calibration data received from `get_calibration/0` or decoded map
  from calibration data.

  ```
  %{
    accel: %{
      x: acc_x,
      y: acc_y,
      z: acc_z,
      radius: acc_radius
    },
    mag: %{
      x: mag_x,
      y: mag_y,
      z: mag_z,
      radius: mag_radius
    },
    gyro: %{
      x: gyro_x,
      y: gyro_y,
      z: gyro_z
    }
  }
  ```

  See section 3.6.4 of datasheet for detailed information about the valid
  values for sensor configuration.
  """
  @spec set_calibration(binary) :: set_result
  def set_calibration(data) when is_binary(data) and byte_size(data) == 22 do
    {@accel_offset_x_lsb_addr, data}
  end
  def set_calibration(%{accel: %{x: acc_x, y: acc_y, z: acc_z, radius: acc_radius}, mag: %{x: mag_x, y: mag_y, z: mag_z, radius: mag_radius}, gyro: %{x: gyro_x, y: gyro_y, z: gyro_z}}) do
    {@accel_offset_x_lsb_addr, <<
      acc_x :: size(16)-signed-little,
      acc_y :: size(16)-signed-little,
      acc_z :: size(16)-signed-little,
      mag_x :: size(16)-signed-little,
      mag_y :: size(16)-signed-little,
      mag_z :: size(16)-signed-little,
      gyro_x :: size(16)-signed-little,
      gyro_y :: size(16)-signed-little,
      gyro_z :: size(16)-signed-little,
      acc_radius :: size(16)-signed-little,
      mag_radius :: size(16)-signed-little
    >>}
  end

  @doc """
  Sets the power mode of the BNO055.

  ## Valid Modes
   - :normal - All sensors for selected operational mode are turned on
   - :lowpower - If no motion is detected for a set period of time (default 5 seconds), then then BNO055 enters a low power mode where only the accelerometer is active.
   - :suspend - All sensors and microcontroller are put into sleep mode.

  See section 3.2 of datasheet for more detailed information on power modes.
  """
  @spec set_power_mode(power_mode) :: set_result
  def set_power_mode(:normal), do: {@pwr_mode_addr, <<0x00>>}
  def set_power_mode(:lowpower), do: {@pwr_mode_addr, <<0x01>>}
  def set_power_mode(:suspend), do: {@pwr_mode_addr, <<0x02>>}
  def set_power_mode(inv_mode), do: raise ArgumentError, "Invalid power mode #{inv_mode} given!"

  @doc """
  Sets the current register page for the BNO055. Valid pages are 0 or 1
  """
  @spec set_page(0|1) :: set_result
  def set_page(0), do:  {@page_id_addr, <<0>>}
  def set_page(1), do:  {@page_id_addr, <<1>>}
  def set_page(inv_page), do: raise ArgumentError, "Invalid page #{inv_page} given!"

  @doc """
  Sets the outputed units for orientation mode, temperature, euler angles, gyroscope,
  acceleration.

  ## Orientation Mode
  :windows
  :android

  ## Temperature
  :celsius
  :fahrenheit

  ## Euler Angles
  :degrees
  :radians

  ## Gyroscope angular rate units
  :dps
  :rps

  ## Accleration units
  :ms2
  :mg

  See section 3.6.1 of the datasheet for more details on output units
  """
  @spec set_output_units(:windows|:android, :celsius|:fahrenheit, :degrees|:radians, :dps|:rps, :ms2|:mg) :: set_result
  def set_output_units(orientation, temp, euler, gyro, acc) do
    orientation_val = case orientation do
      :windows -> 0
      :android -> 1
      _ -> raise ArgumentError, "Invalid orientation mode #{orientation} given!"
    end
    temp_val = case temp do
      :celsius -> 0
      :fahrenheit -> 1
      _ -> raise ArgumentError, "Invalid temperature units #{temp} given!"
    end
    euler_val = case euler do
      :degrees -> 0
      :radians -> 1
      _ -> raise ArgumentError, "Invalid euler units #{euler} given!"
    end
    gyro_val = case gyro do
      :dps -> 0
      :rps -> 1
      _ -> raise ArgumentError, "Invalid gyro #{gyro} given!"
    end
    acc_val = case acc do
      :ms2 -> 0
      :mg -> 1
      _ -> raise ArgumentError, "Invalid acceleration units #{acc} given!"
    end

    {
      @unit_sel_addr,
      <<
        orientation_val::size(1),
        0::size(2),
        temp_val::size(1),
        0::size(1),
        euler_val::size(1),
        gyro_val::size(1),
        acc_val::size(1)
      >>
    }
  end

  @doc """
  Sets the axis remap for each of the 3 axis, as well as the sign for each axis as :positive or :negative (inverted)

  Valid axis remap values - :x_axis, :y_axis, :z_axis
  Valid axis sign values - :positive, :negative

  Note two axises cannot be mapped to the same axis remap value.

  See section 3.4 of the datasheet for more information.
  """
  @spec set_axis_mapping(axis_remap, axis_remap, axis_remap, axis_sign, axis_sign, axis_sign) :: set_result
  def set_axis_mapping(x, y, z, x_sign, y_sign, z_sign) do

    x_val = case x do
      :x_axis -> 0
      :y_axis -> 1
      :z_axis -> 2
      _ -> raise ArgumentError, "Invalid x axis mapping x: #{x} given!"
    end
    y_val = case y do
      :x_axis -> 0
      :y_axis -> 1
      :z_axis -> 2
      _ -> raise ArgumentError, "Invalid y axis mapping y: #{y} given!"
    end
    z_val = case z do
      :x_axis -> 0
      :y_axis -> 1
      :z_axis -> 2
      _ -> raise ArgumentError, "Invalid z axis mapping z: #{z} given!"
    end

    case {x,y,z} do
      {_, ^x, _} -> raise ArgumentError, "Invalid axis mappings given, axis mappings must be mutually exclusive. x == y"
      {_, _, ^x} -> raise ArgumentError, "Invalid axis mappings given, axis mappings must be mutually exclusive. x == z"
      {_, _, ^y} -> raise ArgumentError, "Invalid axis mappings given, axis mappings must be mutually exclusive. y == z"
      _ -> true
    end

    x_sign_val = case x_sign do
      :positive -> 0
      :negative -> 1
      _ -> raise ArgumentError, "Invalid x axis sign mapping #{x_sign} given!"
    end
    y_sign_val = case y_sign do
      :positive -> 0
      :negative -> 1
      _ -> raise ArgumentError, "Invalid y axis sign mapping #{y_sign} given!"
    end
    z_sign_val = case z_sign do
      :positive -> 0
      :negative -> 1
      _ -> raise ArgumentError, "Invalid z axis sign mapping #{z_sign} given!"
    end

    data = <<
      0 :: size(2),
      z_val :: size(2),
      y_val :: size(2),
      x_val :: size(2),
      0 :: size(5),
      x_sign_val :: size(1),
      y_sign_val :: size(1),
      z_sign_val :: size(1)
    >>

    {@axis_map_config_addr, data}
  end
  @spec set_axis_mapping(map) :: set_result
  def set_axis_mapping(%{x_axis: x, y_axis: y, z_axis: z, x_sign: x_sign, y_sign: y_sign, z_sign: z_sign}) do
    set_axis_mapping(
      x,
      y,
      z,
      x_sign,
      y_sign,
      z_sign
    )
  end
  @doc """
  BNO055 is reset, rebooting microcontroller and clearing current configuration.
  The Sensor will be unavailable while reseting and your app should sleep before executing
  the next command.
  """
  @spec reset() :: set_result
  def reset(), do: {@sys_trigger_addr, <<0x20>>}

  @doc """
  Resets the system trigger back to 0x00. All bits off.
  """
  @spec reset_system_trigger() :: set_result
  def reset_system_trigger(), do: {@sys_trigger_addr, <<0x00 :: size(8)>>}

  @doc """
  Command to get the sensor chip address
  """
  @spec get_chip_address() :: get_result
  def get_chip_address, do:  {@chip_id_addr, 1}

  @doc """
  Command to get system status
  """
  @spec get_system_status() :: get_result
  def get_system_status, do: {@sys_stat_addr, 1}

  @doc """
  Command to get last sensor self test result
  """
  @spec get_self_test_result() :: get_result
  def get_self_test_result, do: {@selftest_result_addr, 1}

  @doc """
  Command to get system error data
  """
  @spec get_system_error_data() :: get_result
  def get_system_error_data, do: {@sys_err_addr, 1}

  @doc """
  Command to get sensor revision infomation
  """
  @spec get_revision_info() :: get_result
  def get_revision_info, do: {@accel_rev_id_addr, 6}

  @doc """
  Command to get calibration status
  """
  @spec get_calibration_status() :: get_result
  def get_calibration_status, do: {@calib_stat_addr, 1}

  @doc """
  Command to get sensor calibration data
  """
  @spec get_calibration() :: get_result
  def get_calibration, do: {@accel_offset_x_lsb_addr, 22}

  @doc """
  Command to get sensor axis remapping
  """
  @spec get_axis_mapping() :: get_result
  def get_axis_mapping, do: {@axis_map_config_addr, 2}

  @doc """
  Command to read latest euler angles from fusion mode
  """
  @spec get_euler_reading() :: get_result
  def get_euler_reading, do: {@euler_h_lsb_addr, 6}

  @doc """
  Command to read latest magnetometer values
  """
  @spec get_magnetometer_reading() :: get_result
  def get_magnetometer_reading, do: {@mag_data_x_lsb_addr, 6}

  @doc """
  Command to read latest gyroscope values
  """
  @spec get_gyroscope_reading() :: get_result
  def get_gyroscope_reading, do: {@gyro_data_x_lsb_addr, 6}

  @doc """
  Command to read latest accelerometer values
  """
  @spec get_accelerometer_reading() :: get_result
  def get_accelerometer_reading, do: {@accel_data_x_lsb_addr, 6}

  @doc """
  Command to read latest linear acceleration values
  """
  @spec get_linear_acceleration_reading() :: get_result
  def get_linear_acceleration_reading, do: {@linear_accel_data_x_lsb_addr, 6}

  @doc """
  Command to read latest gravity values
  """
  @spec get_gravity_reading() :: get_result
  def get_gravity_reading, do: {@gravity_data_x_lsb_addr, 6}

  @doc """
  Command to read latest quaternion values
  """
  @spec get_quaternion_reading() :: get_result
  def get_quaternion_reading, do: {@quaternion_data_w_lsb_addr, 8}

  @doc """
  Command to read latest temperature value
  """
  @spec get_temperature_reading() :: get_result
  def get_temperature_reading, do: {@temp_addr, 1}

  @doc """
  Takes binary data returned from sensor system status and returns decoded string
  """
  @spec decode_system_status(binary) :: String.t
  def decode_system_status(data) do
    case data do
      0 -> "Idle"
      1 -> "System Error"
      2 -> "Initializing Peripherals"
      3 -> "System Iniitalization"
      4 -> "Executing Self-Test"
      5 -> "Sensor fusion algorithm running"
      6 -> "System running without fusion algorithms"
      _ -> "Unknown status: #{data}"
    end
  end

  @doc """
  Takes binary data returned from sensor self test and returns decoded data in a map

  %{
    mcu: "Pass",
    gyro: "Pass",
    mag: "Fail",
    accel: "Fail"
  }
  """
  @spec decode_self_test_result(binary) :: map
  def decode_self_test_result(data) do
    <<
      _ :: size(4),
      mcu_st :: size(1),
      gyro_st :: size(1),
      mag_st :: size(1),
      acc_st :: size(1)
    >> = data

    %{
      mcu: (if mcu_st == 1, do: "Pass", else: "Fail"),
      gyro: (if gyro_st == 1, do: "Pass", else: "Fail"),
      mag: (if mag_st == 1, do: "Pass", else: "Fail"),
      accel: (if acc_st == 1, do: "Pass", else: "Fail")
    }
  end

  @doc """
  Takes binary data returned from sensor error data and returns decoded string
  """
  @spec decode_system_error_data(binary) :: String.t
  def decode_system_error_data(data) do
    case data do
      0x00 -> "No error"
      0x01 -> "Peripheral initialization error"
      0x02 -> "System initialization error"
      0x03 -> "Self test result failed"
      0x04 -> "Register map value out of range"
      0x05 -> "Register map address out of range"
      0x06 -> "Register map write error"
      0x07 -> "BNO low power mode not available for selected operat ion mode"
      0x08 -> "Accelerometer power mode not available"
      0x09 -> "Fusion algorithm configuration error"
      0x0A -> "Sensor configuration error"
      _ -> "Unknown system error value: #{data}"
    end
  end

  @doc """
  Takes binary data returned from sensor revision info and returns decoded map

  %{
    accel: 0,
    mag: 0,
    gyro: 0,
    bl: 0,
    sw: 0
  }
  """
  @spec decode_revision_info(binary) :: map
  def decode_revision_info(data) do
    <<
      accel_rev::size(8),
      mag_rev::size(8),
      gyro_rev::size(8),
      sw_rev::size(16),
      bl_rev::size(8)
    >> = data

    %{
      accel: accel_rev,
      mag: mag_rev,
      gyro: gyro_rev,
      bl: bl_rev,
      sw: sw_rev
    }
  end

  @doc """
  Takes binary data returned from sensor calibration status and returns decoded map

  %{
    system: :not_calibrated,
    gyro: :fully_calibrated,
    accel: :fully_calibrated,
    mag: :not_calibrated
  }
  """
  @spec decode_calibration_status(binary) :: map
  def decode_calibration_status(data) do
    <<
      sys_stat::size(2),
      gyr_stat::size(2),
      acc_stat::size(2),
      mag_stat::size(2)
    >> = data

    %{
      system: (if (sys_stat == 3), do: :fully_calibrated, else: :not_calibrated),
      gyro: (if (gyr_stat == 3), do: :fully_calibrated, else: :not_calibrated),
      accel: (if (acc_stat == 3), do: :fully_calibrated, else: :not_calibrated),
      mag: (if (mag_stat == 3), do: :fully_calibrated, else: :not_calibrated)
    }
  end

  @doc """
  Takes binary data returned from sensor calibration and returns decoded map

  %{
    %{
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
  }
  """
  @spec decode_calibration(binary) :: map
  def decode_calibration(data) when byte_size(data) == 22 do
    <<
      acc_x :: size(16)-signed-little,
      acc_y :: size(16)-signed-little,
      acc_z :: size(16)-signed-little,
      mag_x :: size(16)-signed-little,
      mag_y :: size(16)-signed-little,
      mag_z :: size(16)-signed-little,
      gyro_x :: size(16)-signed-little,
      gyro_y :: size(16)-signed-little,
      gyro_z :: size(16)-signed-little,
      acc_radius :: size(16)-signed-little,
      mag_radius :: size(16)-signed-little
    >> = data

    %{
      accel: %{
        x: acc_x,
        y: acc_y,
        z: acc_z,
        radius: acc_radius
      },
      mag: %{
        x: mag_x,
        y: mag_y,
        z: mag_z,
        radius: mag_radius
      },
      gyro: %{
        x: gyro_x,
        y: gyro_y,
        z: gyro_z
      }
    }
  end

  @doc """
  Takes binary data returned from sensor axis remapping and returns decoded map

  %{
      x_axis: :x_axis,
      y_axis: :y_axis,
      z_axis: :z_axis,
      x_sign: :positive,
      y_sign: :negative,
      z_sign: :positive
    }
  """
  @spec decode_axis_mapping(binary) :: map
  def decode_axis_mapping(data) do
    <<
      _ :: size(2),
      z :: size(2),
      y :: size(2),
      x :: size(2),
      _ :: size(5),
      x_sign :: size(1),
      y_sign :: size(1),
      z_sign :: size(1)
    >> = data

    %{
      x_axis: get_axis_mapping_from_val(x),
      y_axis: get_axis_mapping_from_val(y),
      z_axis: get_axis_mapping_from_val(z),
      x_sign: get_axis_sign_from_val(x_sign),
      y_sign: get_axis_sign_from_val(y_sign),
      z_sign: get_axis_sign_from_val(z_sign)
    }
  end

  defp get_axis_mapping_from_val(0), do: :x_axis
  defp get_axis_mapping_from_val(1), do: :y_axis
  defp get_axis_mapping_from_val(2), do: :z_axis
  defp get_axis_sign_from_val(0), do: :positive
  defp get_axis_sign_from_val(1), do: :negative

  @spec decode_euler_reading(binary, :degrees|:radians) :: map | :no_data
  def decode_euler_reading(data, units \\ :degrees)
  def decode_euler_reading(<<>>, _), do: :no_data
  def decode_euler_reading(data, :degrees), do: _decode_euler(data, 16.0)
  def decode_euler_reading(data, :radians), do: _decode_euler(data, 900.0)

  defp _decode_euler(data, unit_factor) do
    <<
  	  heading_rdg :: size(16)-signed-little,
  	  roll_rdg :: size(16)-signed-little,
  	  pitch_rdg :: size(16)-signed-little
  	>> = data

  	heading = heading_rdg / unit_factor
  	roll = roll_rdg / unit_factor
  	pitch = pitch_rdg / unit_factor

  	%{
  	  heading: heading,
  	  roll: roll,
  	  pitch: pitch,
  	}
  end

  @spec decode_magnetometer_reading(binary) :: map | :no_data
  def decode_magnetometer_reading(<<>>), do: :no_data
  def decode_magnetometer_reading(data), do: _decode_vector(data, 16.0)

  @spec decode_gyroscope_reading(binary, :dps|:rps) :: map | :no_data
  def decode_gyroscope_reading(data, units \\ :dps)
  def decode_gyroscope_reading(<<>>, _), do: :no_data
  def decode_gyroscope_reading(data, :dps), do: _decode_vector(data, 16.0)
  def decode_gyroscope_reading(data, :rps), do: _decode_vector(data, 900.0)

  @spec decode_accelerometer_reading(binary, :ms2|:mg) :: map | :no_data
  def decode_accelerometer_reading(data, units \\ :ms2)
  def decode_accelerometer_reading(<<>>, _), do: :no_data
  def decode_accelerometer_reading(data, :ms2), do: _decode_vector(data, 100.0)
  def decode_accelerometer_reading(data, :mg), do: _decode_vector(data, 1.0)

  @spec decode_linear_acceleration_reading(binary, :ms2|:mg) :: map | :no_data
  def decode_linear_acceleration_reading(data, units \\ :ms2)
  def decode_linear_acceleration_reading(<<>>, _), do: :no_data
  def decode_linear_acceleration_reading(data, :ms2), do: _decode_vector(data, 100.0)
  def decode_linear_acceleration_reading(data, :mg), do: _decode_vector(data, 1.0)

  @spec decode_gravity_reading(binary, :ms2|:mg) :: map | :no_data
  def decode_gravity_reading(data, units \\ :ms2)
  def decode_gravity_reading(<<>>, _), do: :no_data
  def decode_gravity_reading(data, :ms2), do: _decode_vector(data, 100.0)
  def decode_gravity_reading(data, :mg), do: _decode_vector(data, 1.0)

  @quaternion_scale (1.0 / :math.pow(2, 14))

  @spec decode_quaternion_reading(binary) :: map | :no_data
  def decode_quaternion_reading(<<>>), do: :no_data
  def decode_quaternion_reading(data) do
    <<
      w_raw :: size(16)-signed-little,
      x_raw :: size(16)-signed-little,
      y_raw :: size(16)-signed-little,
      z_raw :: size(16)-signed-little
    >> = data

    x_val = x_raw * @quaternion_scale
    y_val = y_raw * @quaternion_scale
    z_val = z_raw * @quaternion_scale
    w_val = w_raw * @quaternion_scale

    %{
      x: x_val,
      y: y_val,
      z: z_val,
      w: w_val
    }
  end


  defp _decode_vector(data, unit_factor) do
    <<
      x_raw :: size(16)-signed-little,
      y_raw :: size(16)-signed-little,
      z_raw :: size(16)-signed-little
    >> = data

    x_val = x_raw / unit_factor
    y_val = y_raw / unit_factor
    z_val = z_raw / unit_factor

    %{
      x: x_val,
      y: y_val,
      z: z_val
    }
  end

  @doc """
  Takes result from get / set functions and returns binary data
  to be written to serial port for sensor.
  """
  @spec serial_write_data(set_result|get_result) :: binary
  def serial_write_data({address, data}) when is_binary(data) do
    <<
      0xAA :: size(8), # Start Byte
      0x00 :: size(8), # Write
      address :: size(8),
      byte_size(data) :: size(8),
      data :: binary
    >>
  end
  def serial_write_data({address, length}) when is_integer(length) do
    <<
      0xAA :: size(8), # Start Byte
      0x01 :: size(8), # Read
      address :: size(8),
      length :: size(8)
    >>
  end

  @doc """
  Takes result from get / set functions and returns binary data
  to be written to i2c for sensor. Note get functions will also require
  reading from i2c.
  """
  @spec i2c_write_data(set_result|get_result) :: binary
  def i2c_write_data({address, data}) when is_binary(data) do
    <<address :: size(8), data :: binary>>
  end
  def i2c_write_data({address, length}) when is_integer(length) do
    <<address :: size(8)>>
  end
end
