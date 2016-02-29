use Mix.Config

process_names = %{
    supervisor: :bno055sup,
    eventmgr: :bno055eventmgr
}

config :bno055, [
  names: process_names,
  sensors: [
    %{
      name: "ch1",
      i2c: "i2c-1",
      gproc: "bno055_ch1",
    }
  ]
]
