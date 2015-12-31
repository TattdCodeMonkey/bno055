use Mix.Config

process_names = %{
    supervisor: :bno055sup,
    eventmgr: :bno055mgr
}

ch1_process_names = %{
  state: :ch1state,
}

config :bno055, [
  names: process_names,
  sensors: [
    %{
      name: "ch1",
      i2c: "i2c-1",
      median: %{
        enable: false,
        samples: 5,
      },
      offsets: %{
        pitch: 0.0,
        roll: 0.0,
        heading: 0.0
      }
    }
  ]
]
