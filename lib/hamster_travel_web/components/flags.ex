defmodule HamsterTravelWeb.Flags do
  @moduledoc """
  Renders flags
  """
  use HamsterTravelWeb, :component

  def flag(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <img
      src={Routes.static_path(HamsterTravelWeb.Endpoint, "/images/flags/#{@size}/#{@country}.png")}
      alt={"Country #{@country}"}
      style={"width: #{@size}px;  height: #{@size}px"}
      class={@class}
    />
    """
  end
end
