defmodule BNO055.EventHandler do
	use GenEvent
	require Logger

	def init(args) do
		{:ok, args}
	end

	def handle_event({:reading, data}, state) do
		case data do
			%{readings: readings, table_name: table} ->
				BNO055.SensorState.update(table, readings)
			_ -> 
				Logger.debug("Received unhandled reading event: {:reading, #{inspect data}}")
		end

		{:ok, state}
	end

	def handle_event(event, state) do
		Logger.debug("Received unhandled event: #{inspect event}")

		{:ok, state}
	end
end