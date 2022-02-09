defmodule ModularAudioElixirWeb.PageView do
  use ModularAudioElixirWeb, :view

  def render("update_module.json", _opts) do
    %{success: true}
  end
end
