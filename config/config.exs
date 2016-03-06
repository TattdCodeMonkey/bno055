use Mix.Config

config :bno055, [
  names: %{
      supervisor: :bno055sup
  },
  sensors: [
    %{
      name: "ch1",
      i2c: "i2c-1",
      gproc: "bno055_ch1",
    }
  ]
]
