defmodule BNO055Test do
  use ExUnit.Case
  doctest BNO055

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "set_mode config" do
    assert BNO055.set_mode(:config) == {0x3d, <<0x00>>}
  end

  test "set_mode acconly" do
    assert BNO055.set_mode(:acconly) == {0x3d, <<0x01>>}
  end

  test "set_mode magonly" do
    assert BNO055.set_mode(:magonly) == {0x3d, <<0x02>>}
  end

  test "set_mode gyroonly" do
    assert BNO055.set_mode(:gyroonly) == {0x3d, <<0x03>>}
  end

  test "set_mode accmag" do
    assert BNO055.set_mode(:accmag) == {0x3d, <<0x04>>}
  end

  test "set_mode accgyro" do
    assert BNO055.set_mode(:accgyro) == {0x3d, <<0x05>>}
  end

  test "set_mode maggyro" do
    assert BNO055.set_mode(:maggyro) == {0x3d, <<0x06>>}
  end

  test "set_mode amg" do
    assert BNO055.set_mode(:amg) == {0x3d, <<0x07>>}
  end

  test "set_mode imu" do
    assert BNO055.set_mode(:imu) == {0x3d, <<0x08>>}
  end

  test "set_mode compass" do
    assert BNO055.set_mode(:compass) == {0x3d, <<0x09>>}
  end

  test "set_mode m4g" do
    assert BNO055.set_mode(:m4g) == {0x3d, <<0x0A>>}
  end

  test "set_mode ndof_fmc_off" do
    assert BNO055.set_mode(:ndof_fmc_off) == {0x3d, <<0x0B>>}
  end

  test "set_mode ndof" do
    assert BNO055.set_mode(:ndof) == {0x3d, <<0x0C>>}
  end

  test "set_mode invalid" do
    assert_raise ArgumentError, fn ->
      BNO055.set_mode(:error)
    end
  end

  test "set_external_crystal true" do
    assert BNO055.set_external_crystal(true) == {0x3f, <<0x80>>}
  end

  test "set_external_crystal false" do
    assert BNO055.set_external_crystal(false) == {0x3f, <<0x00>>}
  end
end
