defmodule HamsterTravelWeb.Avatar do
  @moduledoc """
  Renders user's avatar
  """
  use Phoenix.Component

  def avatar(assigns) do
    background_image = "background-image: url(\"#{assigns.url}\");"

    ~H"""
      <div
        title={@title}
        class="w-10 h-10 bg-zinc-200 dark:bg-zinc-800 bg-cover bg-center rounded-full shadow-inner"
        style={background_image}
      >
      </div>
    """
  end
end
