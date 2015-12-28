# Bno055

This is an OTP application for reading the BNO055 absolute orientation sensor. It utilizes elixir_ale for configuring and reading the sensor on the i2c bus.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add bno055 to your list of dependencies in `mix.exs`:

        def deps do
          [{:bno055, "~> 0.0.1"}]
        end

  2. Ensure bno055 is started before your application:

        def application do
          [applications: [:bno055]]
        end
