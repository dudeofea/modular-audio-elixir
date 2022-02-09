defmodule ModularAudioElixirWeb.PageController do
  use ModularAudioElixirWeb, :controller

  def index(conn, _params) do
    mods = GenServer.call(AudioServer, :get_modules)
    render(conn, "index.html", mods: mods)
  end

  def update_module(conn, params) do
    {int_id, _} = Integer.parse(params["id"])
    GenServer.cast(AudioServer, {
      :update_module,
      int_id,
      String.to_existing_atom(params["key"]),
      params["value"]
    })
    render(conn, "update_module.json");
  end
end
