defmodule BNO055.EventHandler do
	use GenEvent
	require Logger

	def init(args) do
		{:ok, args}
	end

	def handle_event({type, %{table_name: table, data: evt_data} = data}, state)
	  when is_list(evt_data) do
		  BNO055.SensorState.update(table, evt_data)	

		  {:ok, state}
  end

	def handle_event(event, state) do
		Logger.debug("Received unhandled event: #{inspect event}")

		{:ok, state}
	end
end