defmodule BNO055.Sensor do
  use GenServer
  use BNO055.SensorInterface, :constants
  require Logger

  @max_consecutive_failed_writes 20

  defmodule State do
    defstruct sensor_config: nil, state_name: nil, bus_name: nil, bus_pid: nil, write_fails: 0
  end


  def start_link(args, opts \\ []) do
    res = {:ok, pid} = GenServer.start_link(__MODULE__, args, opts)

    Process.send_after(pid, :initialize, read_interval)

    res
  end

  def init(%State{} = args) do
  	BNO055.SensorState.init(args.state_name)

    {:ok, args}
  end

  def handle_info(:initialize, state), do: {:noreply, initialize(state)}

  def handle_info(:timed_read, state) do
  	state01 = state
  	|> timed_read
  	|> read_imu

  	{:noreply, state01}
  end

  def handle_info(:timed_sys_status, state) do
  	state01 = state |> timed_sys_status |> get_system_status

  	{:noreply, state01}
  end

  defp initialize(state) do
  	Logger.debug "Initializing #{state.sensor_config.name} BNO055 Sensor"

    if state.bus_name == nil, do: Logger.warn "No bus name, faux sensor used"
  	# Switch to config mode
  	state
    |> init_wait_for_addr
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
  	|> timed_read(10000)
  end

  defp read_interval, do: 50

  defp timed_read(state), do: timed_read(state, read_interval)

  defp timed_read(state, interval) do
  	Process.send_after(self(),:timed_read, interval)

  	state
  end

  defp timed_sys_status(state) do
		Process.send_after(self(), :timed_sys_status, 2000)

		state
  end

  defp read_imu(state) do
  	case read_from_sensor(state, @euler_h_lsb_addr, 6) do
  		{:ok, <<>>, no_data_state} -> no_data_state
  		{:ok, data, data_state} ->
  			process_imu_data(data_state, data)
  	end
  end

  defp process_imu_data(%State{} = state, data) do
  	<<
  	  heading_rdg :: size(16)-signed-little,
  	  roll_rdg :: size(16)-signed-little,
  	  pitch_rdg :: size(16)-signed-little
  	>> = data

  	heading = heading_rdg / 16.0
  	roll = roll_rdg / 16.0
  	pitch = pitch_rdg / 16.0

    data = [
      heading: heading,
      roll: roll,
      pitch: pitch
    ]

  	msg = {:euler_reading, data}

    BNO055.SensorState.update(state.state_name, data)

  	raise_event(state, msg)

  	state
  end

  defp process_system_status(state, {<<>>, <<>>, <<>>}), do: state
  defp process_system_status(state, {<<>>, _, _}), do: state
  defp process_system_status(state, {_, <<>>, _}), do: state
  defp process_system_status(state, {_, _,<<>>}), do: state
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

  defp set_page(state, page) do
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

  defp get_rev_info(%{bus_name: nil} = state), do: state
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

	{:ok, state1} = write_to_sensor(state, @opr_mode_addr, mode_val)
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

  defp init_wait_for_addr(state) do
    Logger.debug "Waiting for address to start initializing sensor"

    {:ok, state01} = wait_for_addr(state)

    state01
  end

  defp wait_for_addr(state), do: wait_for_addr(state, 0)
  defp wait_for_addr(_, 1000), do: {:error, :timeout_waiting_for_address}
  defp wait_for_addr(state, cnt) do
  	case read_from_sensor(state, @chip_id_addr, 1) do
  		{:ok, <<>>, no_data_state} -> {:ok, no_data_state}
  		{:ok, data, data_state} ->
  			case data do
  				<<@bno055_id>> -> {:ok, data_state}
  				_ ->
  					:timer.sleep(10)
  					wait_for_addr(data_state, cnt + 1)
  			end
  		{:error, reason, error_state} -> {:error, reason, error_state}
  	end
  end

  defp write_to_sensor(%{bus_name: nil} = state, _addr, _data), do: {:ok, state}
  defp write_to_sensor(%{bus_name: name, bus_pid: nil} = state, addr, data) do
  	case Process.whereis(name) do
  		nil -> {:ok, <<>>, state}
  		pid ->
  			bus_state = %{state| bus_pid: pid}
			write_to_sensor(bus_state, addr, data)
  	end
  end
  defp write_to_sensor(state, addr, data) do
    case GenServer.call(state.bus_pid, {:write, <<addr>> <> data}) do
      :ok ->
        if state.write_fails != 0 do
          {:ok, %{state| write_fails: 0}}
        else
          {:ok, state}
        end
      {:error, :i2c_write_failed} ->
        write_fails = state.write_fails + 1
        if write_fails > @max_consecutive_failed_writes do
          {:error, :max_consecutive_failed_writes_exceeded}
        else
          {:ok, %{state| write_fails: write_fails}}
        end
    end
  end

  defp read_from_sensor(%{bus_name: nil} = state, _addr, _len), do: {:ok, <<>>, state}
  defp read_from_sensor(%{bus_name: name, bus_pid: nil} = state, addr, len) do
  	case Process.whereis(name) do
  		nil -> {:ok, <<>>, state}
  		pid ->
  			bus_state = %{state| bus_pid: pid}
			read_from_sensor(bus_state, addr, len)
  	end
  end
  defp read_from_sensor(state, addr, len) do
    case GenServer.call(state.bus_pid, {:wrrd, <<addr>>, len}) do
      {:error, :i2c_wrrd_failed} ->
        write_fails = state.write_fails + 1
        if write_fails > @max_consecutive_failed_writes do
          {:error, :max_consecutive_failed_writes_exceeded}
        else
          {:ok, <<>>,  %{state| write_fails: write_fails}}
        end
      data -> {:ok, data, state}
    end
  end

  defp raise_event(%{sensor_config: %{gproc: nil}}, msg) do
    Logger.debug("no event topic defined, msg: #{inspect msg} not sent")

    :ok
  end
  defp raise_event(%{sensor_config: %{gproc: topic}}, msg) do
  	gproc_send(topic, msg)
  end
  defp raise_event(_, msg) do
  	Logger.debug("no event topic defined, msg: #{inspect msg} not sent")

  	:ok
  end

  defp gproc_send(topic, msg) do
    :gproc.send({:p, :l, topic}, {topic, self(), msg})
  end

end
