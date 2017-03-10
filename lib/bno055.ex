defmodule BNO055 do
  use BNO055.SensorInterface
  @moduledoc """
  Set functions return tuple with address and data to be written to that address
  ```elixir
  iex> BNO055.set_mode(:config)
  {0x3D, <<0x00>>}
  ```

  Get functions return tuple with address and number of bytes to read
  ```elixir
  iex> BNO.get_chip_address
  {0x00, 1}

  Decode functions take the data returned from get functions and returns formatted results
  ```
  """


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
  def set_external_crystal(true), do: {@sys_trigger_addr, <<0x80>>}
  def set_external_crystal(false), do: {@sys_trigger_addr, <<0x00>>}

  @doc """
  Set the sensor calibration offsets by sending previously generated
  calibration data received from `get_calibration/0`

  Data is 22 bytes representing sesnor offsets and calibration data.
  """
  def set_calibration(data) when is_binary(data) and byte_size(data) == 22 do
    {@accel_offset_x_lsb_addr, data}
  end

  @doc """
  Sets the power mode of the BNO055.

  ## Valid Modes
   - :normal - All sensors for selected operational mode are turned on
   - :lowpower - If no motion is detected for a set period of time (default 5 seconds), then then BNO055 enters a low power mode where only the accelerometer is active.
   - :suspend - All sensors and microcontroller are put into sleep mode.

  See section 3.2 of datasheet for more detailed information on power modes.
  """
  def set_power_mode(:normal), do: {@pwr_mode_addr, <<0x00>>}
  def set_power_mode(:lowpower), do: {@pwr_mode_addr, <<0x01>>}
  def set_power_mode(:suspend), do: {@pwr_mode_addr, <<0x02>>}
  def set_power_mode(inv_mode), do: raise ArgumentError, "Invalid power mode #{inv_mode} given!"

  @doc """
  BNO055 is reset, rebooting microcontroller and clearing current configuration.
  The Sensor will be unavailable while reseting and your app should sleep before executing
  the next command.
  """
  def reset(), do: {@sys_trigger_addr, <<0x20>>}

  def reset_system_trigger(), do: {@sys_trigger_addr, <<0x00>>}

  @doc """
  Sets the current register page for the BNO055. Valid pages are 0 or 1
  """
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

  def set_axis_mapping(x, y, z, x_sign, y_sign, z_sign) do
    raise NotImplemented, ""
  end

  def get_chip_address, do:  {@chip_id_addr, 1}

  def get_system_status, do: {@sys_stat_addr, 1}

  def get_self_test_result, do: {@selftest_result_addr, 1}

  def get_system_error_data, do: {@sys_err_addr, 1}

  def get_revision_info, do: {@accel_rev_id_addr, 6}

  def get_calibration_status, do: {@calib_stat_addr, 1}

  def get_calibration, do: {@accel_offset_x_lsb_addr, 22}

  def get_axis_mapping, do: {@axis_map_config_addr, 2}

  def get_euler_reading, do: {@euler_h_lsb_addr, 6}

  def get_magnetometer_reading, do: {@mag_data_x_lsb_addr, 6}

  def get_gyroscope_reading, do: {@gyro_data_x_lsb_addr, 6}

  def get_accelerometer_reading, do: {@accel_data_x_lsb_addr, 6}

  def get_linear_acceleration_reading, do: {@linear_accel_data_x_lsb_addr, 6}

  def get_gravity_reading, do: {@gravity_data_x_lsb_addr, 6}

  def get_quaternion_reading, do: {@quaternion_data_w_lsb_addr, 8}

  def get_temperature_reading, do: {@temp_addr, 1}

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
      acc: (if (acc_stat == 3), do: :fully_calibrated, else: :not_calibrated),
      mab: (if (mag_stat == 3), do: :fully_calibrated, else: :not_calibrated)
    }
  end

  def decode_calibration(data) do
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
      acc: %{
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

  def decode_magnetometer_reading(<<>>), do: :no_data
  def decode_magnetometer_reading(data), do: _decode_vector(data, 16.0)

  def decode_gyroscope_reading(data, units \\ :dps)
  def decode_gyroscope_reading(<<>>, _), do: :no_data
  def decode_gyroscope_reading(data, :dps), do: _decode_vector(data, 16.0)
  def decode_gyroscope_reading(data, :rps), do: _decode_vector(data, 900.0)

  def decode_accelerometer_reading(data, units \\ :ms2)
  def decode_accelerometer_reading(<<>>, _), do: :no_data
  def decode_accelerometer_reading(data, :ms2), do: _decode_vector(data, 100.0)
  def decode_accelerometer_reading(data, :mg), do: _decode_vector(data, 1.0)

  def decode_linear_acceleration_reading(data, units \\ :ms2)
  def decode_linear_acceleration_reading(<<>>, _), do: :no_data
  def decode_linear_acceleration_reading(data, :ms2), do: _decode_vector(data, 100.0)
  def decode_linear_acceleration_reading(data, :mg), do: _decode_vector(data, 1.0)

  def decode_gravity_reading(data, units \\ :ms2)
  def decode_gravity_reading(<<>>, _), do: :no_data
  def decode_gravity_reading(data, :ms2), do: _decode_vector(data, 100.0)
  def decode_gravity_reading(data, :mg), do: _decode_vector(data, 1.0)

  @quaternion_scale (1.0 / :math.pow(2, 14))
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

#  use Application
#  require Logger
#
#  def start(_type, _args) do
#    import Supervisor.Spec, warn: false
#    sensors = BNO055.Configuration.sensors
#    case BNO055.Configuration.validate_sensors(sensors) do
#      {:error, errs} ->
#        Logger.error("Errors found validating sensor(s) config: #{inspect sensors}")
#        Enum.map errs, fn err ->
#          Logger.error(err)
#        end
#        raise "Invalid sensor(s) configuration"
#      :ok -> :ok
#    end
#
#    children = [
#      supervisor(BNO055.Supervisor, [])
#    ]
#
#    opts = [strategy: :one_for_one, name: __MODULE__]
#
#    Supervisor.start_link(children, opts)
#  end
end
