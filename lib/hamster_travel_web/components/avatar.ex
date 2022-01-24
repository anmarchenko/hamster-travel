defmodule HamsterTravelWeb.Avatar do
  @moduledoc """
  Shared components dealing with users
  """
  use Phoenix.Component

  def round(%{user: user} = assigns) do
    background_image = "background-image: url(\"#{user.avatar_url}\");"

    size = assigns[:size] || :medium

    ~H"""
      <div
        title={user.name}
        class={classes(size: size)}
        style={background_image}
      >
      </div>
    """
  end

  defp classes(size: size) do
    Enum.join(
      [
        size_class(size),
        "bg-zinc-200 dark:bg-zinc-800 bg-cover bg-center rounded-full shadow-inner"
      ],
      " "
    )
  end

  defp size_class(:medium), do: "w-10 h-10"
  defp size_class(:small), do: "w-6 h-6"
end
