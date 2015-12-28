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
  processes: [
    {:worker, [BNO055.AsoState, [[name: ch1_process_names.state]], [id: ch1_process_names.state]]},
    {:worker, [GenEvent, [[name: process_names.eventmgr]], [id: process_names.eventmgr]]}
  ]
]
