defmodule HamsterTravelWeb.Avatar do
  @moduledoc """
  Shared component dealing with user profile pictures
  """
  use HamsterTravelWeb, :component

  def round(%{user: user} = assigns) do
    background_image = "background-image: url(\"#{user.avatar_url}\");"

    assigns =
      assigns
      |> assign_new(:size, fn -> :medium end)

    ~H"""
    <div title={user.name} class={classes(size: @size)} style={background_image}></div>
    """
  end

  defp classes(size: size) do
    class_list([
      {size_class(size), true},
      {"bg-zinc-200 dark:bg-zinc-800 bg-cover bg-center rounded-full shadow-inner", true}
    ])
  end

  defp size_class(:medium), do: "w-10 h-10"
  defp size_class(:small), do: "w-6 h-6"
end
