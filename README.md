# Bno055

This is an OTP application for reading the BNO055 absolute orientation sensor. It utilizes elixir_ale for configuring and reading the sensor on the i2c bus.

This implementation is ported mostly from the (Adafruit BNO055 Arduino)[https://github.com/adafruit/Adafruit_BNO055] code. 

It currently reads the euler angles from the sensor at 20Hz, raises an event and store the data in an ets table. This supports having multiple sensors if you have multiple i2c channels. In that case an ets table will be created for each sensor. The same GenEvent manager and handler is used. 

This is very much a work in progress and will be evolving as development proceeds and the sensor is tested.

## Installation
(Not yet published)
If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add bno055 to your list of dependencies in `mix.exs`:

        def deps do
          [{:bno055, "~> 0.0.1"}]
        end

  2. Ensure bno055 is started before your application:

        def application do
          [applications: [:bno055]]
        end
