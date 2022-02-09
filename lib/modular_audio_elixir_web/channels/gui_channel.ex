defmodule ModularAudioElixirWeb.GuiChannel do
  use ModularAudioElixirWeb, :channel

  @impl true
  def join("gui", _payload, socket) do
    {:ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("update_module", payload, socket) do
    {int_id, _} = Integer.parse(payload["id"])
    GenServer.cast(AudioServer, {
      :update_module,
      int_id,
      String.to_existing_atom(payload["key"]),
      payload["value"]
    })

    {:reply, :ok, socket}
  end
end
