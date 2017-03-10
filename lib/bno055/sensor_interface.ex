defmodule BNO055.SensorInterface do
  defmacro __using__(_) do
    quote do
      @bno055_id								0xA0
      @chip_id_addr 						0x00
      #  id register definition
      @page_id_addr             0x07
      # Page 0 register definition start
      @chip_id_addr             0x00
      @accel_rev_id_addr        0x01
      @mag_rev_id_addr          0x02
      @gyro_rev_id_addr         0x03
      @sw_rev_id_lsb_addr       0x04
      @sw_rev_id_msb_addr       0x05
      @bl_rev_id_addr           0x06
      # Accel data register
      @accel_data_x_lsb_addr    0x08
      @accel_data_x_msb_addr    0x09
      @accel_data_y_lsb_addr    0x0a
      @accel_data_y_msb_addr    0x0b
      @accel_data_z_lsb_addr    0x0c
      @accel_data_z_msb_addr    0x0d

      # Mag data register
      @mag_data_x_lsb_addr      0x0e
      @mag_data_x_msb_addr      0x0f
      @mag_data_y_lsb_addr      0x10
      @mag_data_y_msb_addr      0x11
      @mag_data_z_lsb_addr      0x12
      @mag_data_z_msb_addr      0x13

      # Gyro data registers
      @gyro_data_x_lsb_addr     0x14
      @gyro_data_x_msb_addr     0x15
      @gyro_data_y_lsb_addr     0x16
      @gyro_data_y_msb_addr     0x17
      @gyro_data_z_lsb_addr     0x18
      @gyro_data_z_msb_addr     0x19

      # Euler data registers
      @euler_h_lsb_addr         0x1a
      @euler_h_msb_addr         0x1b
      @euler_r_lsb_addr         0x1c
      @euler_r_msb_addr         0x1d
      @euler_p_lsb_addr         0x1e
      @euler_p_msb_addr         0x1f

      # Quaternion data registers
      @quaternion_data_w_lsb_addr   0x20
      @quaternion_data_w_msb_addr   0x21
      @quaternion_data_x_lsb_addr   0x22
      @quaternion_data_x_msb_addr   0x23
      @quaternion_data_y_lsb_addr   0x24
      @quaternion_data_y_msb_addr   0x25
      @quaternion_data_z_lsb_addr   0x26
      @quaternion_data_z_msb_addr   0x27

      # Linear acceleration data registers
      @linear_accel_data_x_lsb_addr 0x28
      @linear_accel_data_x_msb_addr 0x29
      @linear_accel_data_y_lsb_addr 0x2a
      @linear_accel_data_y_msb_addr 0x2b
      @linear_accel_data_z_lsb_addr 0x2c
      @linear_accel_data_z_msb_addr 0x2d

      # Gravity data registers
      @gravity_data_x_lsb_addr      0x2e
      @gravity_data_x_msb_addr      0x2f
      @gravity_data_y_lsb_addr      0x30
      @gravity_data_y_msb_addr      0x31
      @gravity_data_z_lsb_addr      0x32
      @gravity_data_z_msb_addr      0x33

      # Temperature data register
      @temp_addr                    0x34

      # Status registers
      @calib_stat_addr              0x35
      @selftest_result_addr         0x36
      @intr_stat_addr               0x37
      @sys_clk_stat_addr            0x38
      @sys_stat_addr                0x39
      @sys_err_addr                 0x3A

      # Unit selection register
      @unit_sel_addr                0x3b
      @data_select_addr             0x3c

      # Mode registers
      @opr_mode_addr                0x3d
      @pwr_mode_addr                0x3e

      @sys_trigger_addr             0x3f
      @temp_source_addr             0x40

      # Axis remap registers
      @axis_map_config_addr         0x41
      @axis_map_sign_addr           0x42

      # SIC registers
      @sic_matrix_0_lsb_addr        0x43
      @sic_matrix_0_msb_addr        0x44
      @sic_matrix_1_lsb_addr        0x45
      @sic_matrix_1_msb_addr        0x46
      @sic_matrix_2_lsb_addr        0x47
      @sic_matrix_2_msb_addr        0x48
      @sic_matrix_3_lsb_addr        0x49
      @sic_matrix_3_msb_addr        0x4a
      @sic_matrix_4_lsb_addr        0x4b
      @sic_matrix_4_msb_addr        0x4c
      @sic_matrix_5_lsb_addr        0x4d
      @sic_matrix_5_msb_addr        0x4e
      @sic_matrix_6_lsb_addr        0x4f
      @sic_matrix_6_msb_addr        0x50
      @sic_matrix_7_lsb_addr        0x51
      @sic_matrix_7_msb_addr        0x52
      @sic_matrix_8_lsb_addr        0x53
      @sic_matrix_8_msb_addr        0x54

      # Accelerometer Offset registers
      @accel_offset_x_lsb_addr      0x55
      @accel_offset_x_msb_addr      0x56
      @accel_offset_y_lsb_addr      0x57
      @accel_offset_y_msb_addr      0x58
      @accel_offset_z_lsb_addr      0x59
      @accel_offset_z_msb_addr      0x5a

      # magnetometer offset registers
      @mag_offset_x_lsb_addr        0x5b
      @mag_offset_x_msb_addr        0x5c
      @mag_offset_y_lsb_addr        0x5d
      @mag_offset_y_msb_addr        0x5e
      @mag_offset_z_lsb_addr        0x5f
      @mag_offset_z_msb_addr        0x60

      # gyroscope offset register s
      @gyro_offset_x_lsb_addr       0x61
      @gyro_offset_x_msb_addr       0x62
      @gyro_offset_y_lsb_addr       0x63
      @gyro_offset_y_msb_addr       0x64
      @gyro_offset_z_lsb_addr       0x65
      @gyro_offset_z_msb_addr       0x66

      # radius registers
      @accel_radius_lsb_addr        0x67
      @accel_radius_msb_addr        0x68
      @mag_radius_lsb_addr          0x69
      @mag_radius_msb_addr          0x6A
    end
  end
end