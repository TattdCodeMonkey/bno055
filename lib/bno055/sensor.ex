defmodule BNO055.Sensor do
  use GenServer
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
  	|> set_mode(:config)
  	|> reset
  	|> set_power_mode(:normal)
  	|> set_output_units
  	|> configure_axis_mapping
  	|> reset_sys_trigger
  	|> set_mode(:ndof)
  	|> timed_read
  end

  defp read_interval, do: 50

  defp timed_read(state) do 
  	Process.send_after(self(),:timed_read, read_interval)

  	state
  end

  @euler_addr 0x1A
  defp read_imu(state) do
  	case read_from_sensor(state, @euler_addr, 6) do
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

  	msg = {:reading, 
  		%{
  			sensor: state.sensor_config.name,
  			readings: [
  				heading: heading,
  				roll: roll,
  				pitch: pitch
  			],
  			state_tbl: state.state_name
  		}
  	}

  	raise_event(state, msg)

  	state
  end

  @mode_addr 0x3D
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

  @sys_trigger_addr 0x3F
  defp reset(state) do
  	Logger.debug("BNO055 resetting sensor")
  	{:ok, state1} = write_to_sensor(state, @sys_trigger_addr, <<0x20>>)

  	Logger.debug("BNO055 waiting for sensor address")
  	{:ok, state2} = wait_for_addr(state1)
  	:timer.sleep(50)

  	state2
  end

  @pwr_mode_addr 0x3E
  @page_id_addr 0x07
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

  @chip_id_addr 0x00
  @bno055_id 0xA0
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
