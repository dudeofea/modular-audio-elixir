defmodule SimpleDrone do
  use GenServer
  use Phoenix.View, root: Path.dirname(__ENV__.file), namespace: SimpleDrone

  def init(id) do
    {:ok, %{
      offset: 0,
      freq: 440,
      mul: 0.1,
      id: id
    }}
  end

  def handle_call({:process, sample_rate, req_frames}, _from, state) do
    {out, new_state} = sine(state, sample_rate, req_frames)
    {:reply, %{out: %{0 => out, 1 => out}}, new_state}
  end

  def handle_call(:render, _from, state) do
    out = Phoenix.View.render(SimpleDrone, "simple_drone.html", state)
    {:reply, out, state}
  end

  def handle_cast({:set, key, val}, state) do
    case Map.has_key?(state, key) do
      true -> {:noreply, Map.put(state, key, val)}
      false -> {:stop, "key not found: " ++ Kernel.inspect(key), state}
    end
  end

  def sample_fn(state, sample_rate, frames, wave_fn) do
    %{offset: offset, freq: freq, mul: mul} = state
    wave_frames = trunc(sample_rate / freq) - 1
    wave_rem = Kernel.rem(frames, wave_frames + 1)
    new_offset = Kernel.rem(offset + frames, wave_frames + 1)
    wave_count =
      case {wave_rem, trunc(frames / (wave_frames + 1))} do
        {0, wc} -> wc
        {_, wc} -> wc + 1
      end
    one_wave = Enum.map(offset..wave_frames+offset, fn x ->
      mul * wave_fn.(x, wave_frames)
    end)

    out =
      0..wave_count-1
      |> Stream.flat_map(fn _ ->
           one_wave
         end)
      |> Enum.take(frames)

    {out, Map.replace(state, :offset, new_offset)}
  end

  def sawtooth(state, sample_rate, frames) do
    sample_fn(state, sample_rate, frames, fn x, max_x ->
      (2.0 * x / (max_x)) - 1.0
    end)
  end

  def sine(state, sample_rate, frames) do
    sample_fn(state, sample_rate, frames, fn x, max_x ->
      :math.sin(2.0 * :math.pi() * x / (max_x + 1))
    end)
  end
end
