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
  def decode_response(<<0xEE :: size(8), status :: size(8)>>) do
    case status do
      0x01 -> :write_success
      0x02 -> :read_fail
      0x03 -> :write_fail
      0x04 -> :invalid_register
      0x05 -> :write_disabled
      0x06 -> :wrong_start_byte
      0x07 -> :bus_over_run
      0x08 -> :max_length_error
      0x09 -> :min_length_error
      0x0A -> :receive_character_timeout
      _ -> :write_unknown_status
    end
  end
  def decode_response(<<0xBB :: size(8), length :: size(8), data :: binary>>) when byte_size(data) >= length do    
    {:read_success, data}
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
    <<address :: size(8), data :: binary>>
  end
  def write_data({address, length}) when is_integer(length) do
    <<address :: size(8)>>
  end
end