defmodule SimpleDroneTest do
  use ExUnit.Case
  doctest SimpleDrone

  test "sawtooth simple frame gen" do
    # 1Hz wave, sample rate = frames
    state = %{offset: 0, freq: 1, mul: 1.0}
    {output, _} = SimpleDrone.sawtooth(state, 5, 5)
    delta = 0.001
    assert Enum.count(output) == 5
    assert_in_delta Enum.at(output, 0), -1.0, delta
    assert_in_delta Enum.at(output, 1), -0.5, delta
    assert_in_delta Enum.at(output, 2), 0.0, delta
    assert_in_delta Enum.at(output, 3), 0.5, delta
    assert_in_delta Enum.at(output, 4), 1.0, delta
  end

  test "sawtooth cuts off frames" do
    # 1.5 waves
    state = %{offset: 0, freq: 1, mul: 1.0}
    {output, _} = SimpleDrone.sawtooth(state, 5, 8)
    delta = 0.001
    assert Enum.count(output) == 8
    assert_in_delta Enum.at(output, 0), -1.0, delta
    assert_in_delta Enum.at(output, 1), -0.5, delta
    assert_in_delta Enum.at(output, 2), 0.0, delta
    assert_in_delta Enum.at(output, 3), 0.5, delta
    assert_in_delta Enum.at(output, 4), 1.0, delta
    assert_in_delta Enum.at(output, 5), -1.0, delta
    assert_in_delta Enum.at(output, 6), -0.5, delta
    assert_in_delta Enum.at(output, 7), 0.0, delta
  end

  test "sawtooth offset calc" do
    # Generate non-whole number of waves
    state = %{offset: 0, freq: 1, mul: 1.0}
    {_, new_state} = SimpleDrone.sawtooth(state, 5, 13)
    assert new_state[:freq] == 1
    assert new_state[:mul] == 1.0
    assert new_state[:offset] == 3
  end

  test "sawtooth offset gen" do
    # Check that generated wave is offse
    state = %{offset: 2, freq: 1, mul: 1.0}
    {output, _} = SimpleDrone.sawtooth(state, 5, 3)
    delta = 0.001
    assert Enum.count(output) == 3
    assert_in_delta Enum.at(output, 0), 0.0, delta
    assert_in_delta Enum.at(output, 1), 0.5, delta
    assert_in_delta Enum.at(output, 2), 1.0, delta
  end

  test "sawtooth keeps extra args" do
    # Generate non-whole number of waves
    state = %{offset: 0, freq: 1, mul: 1.0, extra: 5}
    {_, new_state} = SimpleDrone.sawtooth(state, 5, 13)
    assert new_state[:extra] == 5
  end

  test "sine simple frame gen" do
    # 1Hz wave
    state = %{offset: 0, freq: 1, mul: 1.0}
    {output, _} = SimpleDrone.sine(state, 4, 4)
    delta = 0.001
    assert Enum.count(output) == 4
    assert_in_delta Enum.at(output, 0), 0.0, delta
    assert_in_delta Enum.at(output, 1), 1.0, delta
    assert_in_delta Enum.at(output, 2), 0.0, delta
    assert_in_delta Enum.at(output, 3), -1.0, delta
  end
end
