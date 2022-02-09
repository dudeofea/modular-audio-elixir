defmodule ModularAudioElixir.AudioServer do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: AudioServer)
  end

  def init(:ok) do
    Process.send_after(self(), :ready4more, 0)

    avail_mods = Application.get_env(:modular_audio_elixir, :audio_modules)
    # TODO: this creates all mods, instead add a UI to add them
    # and increments the index every time
    modules =
      avail_mods
      |> Enum.with_index
      |> Enum.map(fn {c, ind} ->
        {:ok, pid} = GenServer.start_link(c, ind)
        {pid, %{}, %{}}
      end)
    {:ok, {{<<>>, <<>>}, modules}}
  end

  def handle_info(:ready4more, {{left, right}, modules}) do
    # send next frames right away
    Xalsa.send_frames(left, 1, true)
    Xalsa.send_frames(right, 2, true)
    Xalsa.wait_ready4more()

    # run modules and get next frames
    sample_rate = Xalsa.rate()
    req_frames = Xalsa.period_size()
    {l, r} = run_modules(modules, sample_rate, req_frames)
    next_frames = {
      Xalsa.float_list_to_binary(l), Xalsa.float_list_to_binary(r)
    }

    {:noreply, {next_frames, modules}}
  end

  def run_modules(modules, sample_rate, req_frames) do
    # run modules
    modules = Enum.map(modules, fn {pid, i, _} ->
      out = GenServer.call(pid, {:process, sample_rate, req_frames})
      #debug_lr(out)
      {pid, i, out}
    end)

    # mix final output
    empty = List.duplicate(0.0, req_frames)
    Enum.reduce(modules, {empty, empty}, fn {_, _, out}, {acc_l, acc_r} ->
      case out do
        %{out: %{0 => out_l, 1 => out_r}} -> {
          Enum.zip_with(out_l, acc_l, fn x, y -> x + y end),
          Enum.zip_with(out_r, acc_r, fn x, y -> x + y end)}
        _ -> {acc_l, acc_r}
      end
    end)
  end

  def handle_call(:get_modules, _from, {audio, modules}) do
    {:reply, modules, {audio, modules}}
  end

  def handle_cast({:add_module, new_mod}, {audio, modules}) do
    {:ok, pid} = GenServer.start_link(new_mod, nil)
    {:noreply, {audio, modules ++ {pid, %{}, %{}}}}
  end

  def handle_cast({:update_module, id, key, new_val}, {audio, modules}) do
    case Enum.at(modules, id) do
      {pid, _, _} -> GenServer.cast(pid, {:set, key, new_val})
      nil -> nil
    end
    {:noreply, {audio, modules}}
  end

  def debug_lr(%{out: %{0 => l, 1 => r}}) do
    IO.inspect({Enum.count(l), Enum.count(r)})
  end
end
