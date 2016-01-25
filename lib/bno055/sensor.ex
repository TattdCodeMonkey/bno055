defmodule BNO055.Sensor do
  use GenServer
  use BNO055.SensorInterface, :constants
  require Logger

  defstruct sensor_config: nil, state_name: nil, bus_names: %{}, bus: nil, bus_pid: nil, evt_mgr: nil, evt_mgr_pid: nil, offsets: nil, median: nil
  def start_link(args, opts \\ []) do
    res = {:ok, pid} = GenServer.start_link(__MODULE__, args, opts)

    Process.send_after(pid, :initialize, read_interval)

    res
  end

  def init(args) do
  	BNO055.SensorState.init(args.state_name)
  	
  	state = case args.bus_names do
  		%{} -> args
  		%{deva: busa, devb: _ } -> 
  			%{args| bus: busa}
		_ -> args
  	end

    {:ok, state}
  end

  def handle_info(:initialize, state), do: {:noreply, initialize(state)}

  def handle_info(:timed_read, state) do
  	state1 = state
  	|> timed_read
  	|> read_imu

  	{:noreply, state1}
  end

  defp initialize(state) do
  	Logger.debug "Initializing #{state.sensor_config.name} BNO055 Sensor"

  	# Switch to config mode
  	state
  	|> set_page(0)
  	|> set_mode(:config)
  	|> reset
  	|> set_power_mode(:normal)
  	|> set_output_units
  	|> configure_axis_mapping
  	|> reset_sys_trigger
  	|> set_mode(:ndof)
  	|> get_system_status
  	|> get_rev_info
  	|> get_calibration
  	|> timed_read
  end

  defp read_interval, do: 50

  defp timed_read(state) do 
  	Process.send_after(self(),:timed_read, read_interval)

  	state
  end


  defp read_imu(state) do
  	case read_from_sensor(state, @euler_h_lsb_addr, 6) do
  		{:ok, <<>>, no_data_state} -> no_data_state
  		{:ok, data, data_state} ->
  			process_imu_data(data_state, data)
  	end
  end

  defp process_imu_data(%__MODULE__{} = state, data) do
  	<<
  	  heading_rdg :: size(16)-signed,
  	  roll_rdg :: size(16)-signed,
  	  pitch_rdg :: size(16)-signed
  	>> = data

  	heading = heading_rdg / 16.0
  	roll = roll_rdg / 16.0
  	pitch = pitch_rdg / 16.0

  	msg = {:euler_reading, 
  		%{
  			sensor: state.sensor_config.name,
  			table_name: state.state_name,
  			data: [
  				heading: heading,
  				roll: roll,
  				pitch: pitch
  			],
  		}
  	}

  	raise_event(state, msg)

  	state
  end

  defp process_system_status(state, {sys, st, err}) do
  	sys_status = case sys do
  		0 -> "Idle"
  		1 -> "System Error"
  		2 -> "Initializing Peripherals"
  		3 -> "System Iniitalization"
  		4 -> "Executing Self-Test"
  		5 -> "Sensor fusion algorithm running"
  		6 -> "System running without fusion algorithms"
  		_ -> "Unknown status: #{sys}"
  	end

  	<<
  	  _ :: size(4),
  	  mcu_st :: size(1),
  	  gyro_st :: size(1),
  	  mag_st :: size(1),
  	  acc_st :: size(1)
  	>> = st

  	self_test = %{
  		mcu: (if mcu_st == 1, do: "Pass", else: "Fail"),
  		gyro: (if gyro_st == 1, do: "Pass", else: "Fail"),
  		mag: (if mag_st == 1, do: "Pass", else: "Fail"),
  		accel: (if acc_st == 1, do: "Pass", else: "Fail")
  	}

  	sys_error = case err do
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
		_ -> "Unknown system error value: #{err}"
  	end

  	msg = {:system_status, 
  		%{
  			sensor: state.sensor_config.name,
  			table_name: state.state_name,
  			data: [
  				system_status: sys_status,
  				system_error: sys_error,
  				self_test: self_test
  			]	
  		}
  	}

  	raise_event(state, msg)

  	state
  end

  defp set_page(state, page \\ 0) do
  	{:ok, state01} = write_to_sensor(state, @page_id_addr, <<page>>)
  	:timer.sleep(10)

  	state01
  end


  defp get_system_status(state) do
  	state01 = set_page(state, 0)
  	{:ok, sys_stat_data, state02} = read_from_sensor(state01, @sys_stat_addr, 1)
  	{:ok, self_test_data, state03} = read_from_sensor(state02, @selftest_result_addr, 1)
  	{:ok, sys_error_data, state04} = read_from_sensor(state03, @sys_err_addr, 1)

  	process_system_status(state04, {sys_stat_data, self_test_data, sys_error_data})
  end

  defp get_rev_info(state) do
		{:ok, <<accel_rev>>, state01} = read_from_sensor(state, @accel_rev_id_addr, 1)
		{:ok, <<mag_rev>>, state02} = read_from_sensor(state01, @mag_rev_id_addr, 1)
		{:ok, <<gyro_rev>>, state03} = read_from_sensor(state02, @gyro_rev_id_addr, 1)
		{:ok, <<bl_rev>>, state04} = read_from_sensor(state03, @bl_rev_id_addr, 1)
		{:ok, <<sw_rev :: size(16)>>, state05} = read_from_sensor(state04, @sw_rev_id_lsb_addr, 2)

		raise_event(state,
			{:revision_info, 
				%{
					sensor: state.sensor_config.name,
  				table_name: state.state_name,
  				data: [
  					revision_info: %{
  						accel: accel_rev,
  						mag: mag_rev,
  						gyro: gyro_rev,
  						bl: bl_rev,
  						sw: sw_rev
  					}
  				]
				}
			}
		)

  	state05
  end

  defp get_calibration(state) do
  	state
  end

  defp set_mode(state, mode) do
	Logger.debug("BNO055 setting sensor mode to #{inspect mode}")

  	mode_val = case mode do
  		:config -> <<0x00>>
  		:acconly -> <<0x01>>
  		:magonly -> <<0x02>>
  		:gyroonly -> <<0x03>>
  		:accmag -> <<0x04>>
  		:accgyro -> <<0x05>>
  		:maggyro -> <<0x06>>
  		:amg -> <<0x07>>
  		:imuplus -> <<0x08>>
  		:compass -> <<0x09>>
  		:m4g -> <<0x0A>>
  		:ndof_fmc_off -> <<0x0B>>
  		:ndof -> <<0x0C>>
  		_ -> <<0x0C>>
	end

	{:ok, state1} = write_to_sensor(state, @mode_addr, mode_val)
	:timer.sleep(30)

  	state1
  end

  defp reset(state) do
  	Logger.debug("BNO055 resetting sensor")
  	{:ok, state1} = write_to_sensor(state, @sys_trigger_addr, <<0x20>>)
  	:timer.sleep(650)

  	Logger.debug("BNO055 waiting for sensor address")
  	{:ok, state2} = wait_for_addr(state1)
  	:timer.sleep(50)

  	state2
  end

  defp set_power_mode(state, mode) do
  	Logger.debug("BNO055 setting sensor power mode to #{inspect mode}")

  	mode_val = case mode do
  		:normal -> <<0x00>>
  		:lowpower -> <<0x01>>
  		:suspend -> <<0x02>>
  		_ -> <<0x00>>
  	end

  	{:ok, state1} = write_to_sensor(state, @pwr_mode_addr, mode_val)
	:timer.sleep(10)

	{:ok, state2} = write_to_sensor(state1, @page_id_addr, <<0x00>>)

  	state2
  end

  defp set_output_units(state) do
  	state
  end

  defp configure_axis_mapping(state) do
  	state
  end

  defp reset_sys_trigger(state) do
  	{:ok, state1} = write_to_sensor(state, @sys_trigger_addr, <<0x00>>)
  	:timer.sleep(10)

  	state1
  end

  
  defp wait_for_addr(state) do
  	case read_from_sensor(state, @chip_id_addr, 1) do
  		{:ok, <<>>, no_data_state} -> {:ok, no_data_state}
  		{:ok, data, data_state} ->
  			case data do
  				<<@bno055_id>> -> {:ok, data_state}
  				_ ->
  					:timer.sleep(10) 
  					wait_for_addr(data_state)
  			end
  		{:error, reason, error_state} -> {:error, reason, error_state}
  	end
  end

  defp write_to_sensor(%{bus: nil} = state, _addr, _data), do: {:ok, state}
  defp write_to_sensor(%{bus: name, bus_pid: nil} = state, addr, data) do
  	case Process.whereis(name) do
  		nil -> {:ok, <<>>, state}
  		pid -> 
  			bus_state = %{state| bus_pid: pid}
			write_to_sensor(bus_state, addr, data)
  	end
  end
  defp write_to_sensor(state, addr, data) do
  	:ok = GenServer.call(state.bus_pid, {:write, <<addr>> <> data})

  	{:ok, state}
  end

  defp read_from_sensor(%{bus: nil} = state, _addr, _len), do: {:ok, <<>>, state}
  defp read_from_sensor(%{bus: name, bus_pid: nil} = state, addr, len) do
  	case Process.whereis(name) do
  		nil -> {:ok, <<>>, state}
  		pid -> 
  			bus_state = %{state| bus_pid: pid}
			read_from_sensor(bus_state, addr, len)
  	end
  end
  defp read_from_sensor(state, addr, len) do
  	data = GenServer.call(state.bus_pid, {:wrrd, <<addr>>, len})

  	{:ok, data, state}
  end

  defp raise_event(%{evt_mgr: nil} = state, _msg), do: {:ok, state}
  defp raise_event(%{evt_mgr_pid: nil} = state, msg) do
  	case Process.whereis(state.evt_mgr) do
  		nil -> {:ok, state}
  		pid -> 
  			pid_state = %{state| evt_mgr_pid: pid}
  			raise_event(pid_state, msg)
  	end
  end
  defp raise_event(%{evt_mgr_pid: epid} = state, msg) do
  	:ok = GenEvent.notify(epid, msg)

  	{:ok, state}
  end
  	
end
