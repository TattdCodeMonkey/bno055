defmodule BNO055.SensorState do
  require Logger

  @euler_ms [{{:"$1", :"$2"},[{:or, {:"==", :"$1", :roll},{:or, {:"==", :"$1", :heading}, {:"==", :"$1", :pitch}}}], [{{:"$1", :"$2"}}]}]
  @default_data [status: nil, pitch: nil, roll: nil, heading: nil, quaternion: nil]

  def init(name) do
    case :ets.info(name) do
      :undefined ->

        ^name = create_table(name)
        init_table(name)
        :ok
      _ -> :ok
    end
  end

  def create_table(name) do
    Logger.debug "creating ets table #{name}"

    :ets.new(name, [:set, :named_table, :public])
  end

  def init_table(name) do
    Logger.debug "initializing ets table #{name} with: #{inspect @default_data}"
    :ets.insert(name, @default_data)
  end

  def get_euler(name) do
    :ets.select(name, @euler_ms)
    |> Enum.into(%{})
  end

  def update(name, value), do: true = :ets.insert(name, value)

  def get(name, key), do: :ets.lookup(name, key) |> Enum.into(%{})
  def get(name), do: :ets.match_object(name, {:"$1", :"$2"}) |> Enum.into(%{})

  def debug(name), do: get(name) |> inspect |> Logger.debug 
end
