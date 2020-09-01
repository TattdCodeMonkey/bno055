# BNO-055

This module is used to create commands for interacting with a Bosch BNO055 sensor. This module is intended to be an unopinionated collection of functions to created data for communicating with the sensor, but does not handle actual communication.

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

```elixir
iex> BNO055.set_mode(:config) |> BNO055.i2c_write_data
<<0x3D, 0x00>>

iex> BNO055.set_mode(:config) |> BNO055.serial_write_data
<<0xAA, 0x00, 0x3D, 0x01, 0x00>>
```

Decode functions take the binary data returned from sensor and formats the result.

## Installation
Available in Hex, the package can be installed as:

  1. Add bno055 to your list of dependencies in `mix.exs`:

        def deps do
          [{:bno055, "~> 1.0"}]
        end
