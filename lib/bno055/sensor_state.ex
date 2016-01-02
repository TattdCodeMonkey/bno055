defmodule BNO055.SensorState do

  @euler_ms [{{:"$1", :"$2"},[{:or, {:"==", :"$1", :roll},{:or, {:"==", :"$1", :heading}, {:"==", :"$1", :pitch}}}], [{{:"$1", :"$2"}}]}]

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
    :ets.new(name, [:set, :named_table, :protected])
  end

  def init_table(name) do
    :ets.insert(name, [
      status: nil,
      pitch: nil,
      roll: nil,
      heading: nil,
      temp: nil,
      quaternion: nil,
      mag: nil,
      gryo: nil,
      accel: nil,
      calibration: nil,
      cal_gyro: nil,
      cal_accel: nil,
      cal_mag: nil,
    ])
  end

  def get_euler(name) do
    :ets.select(name, @euler_ms)
    |> Enum.into(%{})
  end

  def update(name, value), do: true = :ets.insert(name, value)

  def get(name, key), do: :ets.lookup(name, key)
  def get(name), do: :ets.match_object(name, {:"$1", :"$2"}) |> Enum.into(%{})
end
