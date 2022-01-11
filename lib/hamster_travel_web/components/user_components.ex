defmodule HamsterTravelWeb.UserComponents do
  @moduledoc """
  Shared components dealing with users
  """
  use Phoenix.Component

  def avatar(%{user: user} = assigns) do
    background_image = "background-image: url(\"#{user.avatar_url}\");"

    ~H"""
      <div
        title={user.name}
        class="w-10 h-10 bg-zinc-200 dark:bg-zinc-800 bg-cover bg-center rounded-full shadow-inner"
        style={background_image}
      >
      </div>
    """
  end
end
