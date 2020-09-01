defmodule BNO055.IO.SerialTest do
  use ExUnit.Case

  test "write data" do
    assert <<0xAA, 0x00, 0x0A, 4, 1,2,3,4>> == BNO055.IO.Serial.write_data({0x0A, <<1,2,3,4>>})
    assert <<0xAA, 0x00, 0x1F, 1, 6>> == BNO055.IO.Serial.write_data({0x1F, <<6>>})

    assert <<0xAA, 0x01, 0x1F, 8>> == BNO055.IO.Serial.write_data({0x1F, 8})
  end  

  test "decode write_response" do
    assert {:ok, :write_success, <<>>} == BNO055.IO.Serial.decode_response(<<0xEE, 0x01>>)
    assert {:ok, :write_success, <<0xBB, 0x05>>} == BNO055.IO.Serial.decode_response(<<0xEE, 0x01, 0xBB, 0x05>>)
    
    assert {:error, :read_fail, <<>>} == BNO055.IO.Serial.decode_response(<<0xEE, 0x02>>)
    assert {:error, :write_fail, <<>>} == BNO055.IO.Serial.decode_response(<<0xEE, 0x03>>)
    assert {:error, :invalid_register, <<>>} == BNO055.IO.Serial.decode_response(<<0xEE, 0x04>>)
    assert {:error, :write_disabled, <<>>} == BNO055.IO.Serial.decode_response(<<0xEE, 0x05>>)
    assert {:error, :wrong_start_byte, <<>>} == BNO055.IO.Serial.decode_response(<<0xEE, 0x06>>)
    assert {:error, :bus_over_run, <<>>} == BNO055.IO.Serial.decode_response(<<0xEE, 0x07>>)
    assert {:error, :max_length_error, <<>>} == BNO055.IO.Serial.decode_response(<<0xEE, 0x08>>)
    assert {:error, :min_length_error, <<>>} == BNO055.IO.Serial.decode_response(<<0xEE, 0x09>>)
    assert {:error, :receive_character_timeout, <<>>} == BNO055.IO.Serial.decode_response(<<0xEE, 0x0A>>)
    assert {:error, :write_unknown_status, <<>>} == BNO055.IO.Serial.decode_response(<<0xEE, 0x0F>>)
  end

  test "decode read response" do
    assert {:ok, :read_success, <<1,2,3,4,5>>, <<>>} == BNO055.IO.Serial.decode_response(<<0xBB, 5, 1,2,3,4,5>>)
    assert {:ok, :read_success, <<1,2,3,4,5>>, <<0xBB, 4, 2>>} == BNO055.IO.Serial.decode_response(<<0xBB, 5, 1,2,3,4,5, 0xBB, 4, 2>>)
    
    assert :response_incomplete == BNO055.IO.Serial.decode_response(<<0xBB, 5, 1,2,3>>)
  end
end

defmodule BNO055.IO.I2cTest do
  use ExUnit.Case

  test "write_data" do
    assert {:write, <<0x1F, 1,1,1>>} == BNO055.IO.I2c.write_data({0x1F, <<1,1,1>>})

    assert {:wrrd, <<0x1F>>, 3} == BNO055.IO.I2c.write_data({0x1F, 3})
  end
end