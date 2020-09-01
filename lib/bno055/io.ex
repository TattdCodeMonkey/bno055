defmodule BNO055.IO.Serial do
  @type register_address :: 0..0x6A
  @type set_result :: {register_address, binary}
  @type get_result :: {register_address, pos_integer}
  
  @doc """
  Takes result from get / set functions and returns binary data
  to be written to serial port for sensor.
  """
  @spec write_data(set_result|get_result) :: binary
  def write_data({address, data}) when is_binary(data) do
    <<
      0xAA :: size(8), # Start Byte
      0x00 :: size(8), # Write
      address :: size(8),
      byte_size(data) :: size(8),
      data :: binary
    >>
  end
  def write_data({address, length}) when is_integer(length) do
    <<
      0xAA :: size(8), # Start Byte
      0x01 :: size(8), # Read
      address :: size(8),
      length :: size(8)
    >>
  end
  def decode_response(<<0xEE :: size(8), status :: size(8), rest:: binary>>) do
    {resp, result} = case status do
      0x01 -> {:ok, :write_success}
      0x02 -> {:error, :read_fail}
      0x03 -> {:error, :write_fail}
      0x04 -> {:error, :invalid_register}
      0x05 -> {:error, :write_disabled}
      0x06 -> {:error, :wrong_start_byte}
      0x07 -> {:error, :bus_over_run}
      0x08 -> {:error, :max_length_error}
      0x09 -> {:error, :min_length_error}
      0x0A -> {:error, :receive_character_timeout}
      _ -> {:error, :write_unknown_status}
    end

    {resp, result, rest}
  end
  def decode_response(<<0xBB :: size(8), length :: size(8), data :: binary>>) when byte_size(data) >= length do    
    <<resp_data :: size(length)-binary, rest :: binary>> = data
    {:ok, :read_success, resp_data, rest}
  end
  def decode_response(<<0xBB :: size(8), _length :: size(8), _data :: binary>>), do: :response_incomplete
end

defmodule BNO055.IO.I2c do
  @type register_address :: 0..0x6A
  @type set_result :: {register_address, binary}
  @type get_result :: {register_address, pos_integer}

  @doc """
  Takes result from get / set functions and returns binary data
  to be written to i2c for sensor. Note get functions will also require
  reading from i2c.
  """
  @spec write_data(set_result|get_result) :: binary
  def write_data({address, data}) when is_binary(data) do
    {:write, <<address :: size(8), data :: binary>>}
  end
  def write_data({address, length}) when is_integer(length) do
    {:wrrd, <<address :: size(8)>>, length}
  end
end