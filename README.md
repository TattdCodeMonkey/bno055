# BNO-055

This is an OTP application for reading the BNO-055 absolute orientation sensor. It utilizes elixir_ale for configuring and reading the sensor on the i2c bus.

This implementation is ported mostly from the (Adafruit BNO055 Arduino)[https://github.com/adafruit/Adafruit_BNO055] code.

It currently reads the euler angles from the sensor at 20Hz, raises an event and store the data in an ets table. This supports having multiple sensors if you have multiple i2c channels. In that case an ets table will be created for each sensor. The same GenEvent manager and handler is used.

This is very much a work in progress and will be evolving as development proceeds and the sensor is tested.

## Installation
Available in Hex, the package can be installed as:

  1. Add bno055 to your list of dependencies in `mix.exs`:

        def deps do
          [{:bno055, "~> 0.0.1"}]
        end

  2. Ensure bno055 is started before your application:

        def application do
          [applications: [:bno055]]
        end

## Configuration

```elixir
config :bno055 [
  sensors: [
    %{
      name: "sensor name",
      i2c: "channel",
      gproc: "topic"
    }
  ]
]
```

- `name` is the name of the sensor and used to create atom names for all the processes in the sensor tree
- `i2c` is the name of the channel this sensor is connected to. `"i2c-1"` for example
- `gproc` is the local property that data will be published to.

## Notes

On startup each sensor will be initialized. Initialization consists of reseting the sensor and setting its configuration. Ten seconds after initialized the sensor's euler angles will be read at 20hz and published to the `gproc` local property and stored in the sensor's `ets` table. The `ets` table name follows the pattern `bno055_[name]_state`

## TODO

 - abstract `sensor.ex` out to allow full unit testing
 - improve test coverage
 - support secondary i2c address via config
 - support other data from sensor, maybe configurable
