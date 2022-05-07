defmodule HamsterTravelWeb.Flag do
  @moduledoc """
  Renders flag by a country code
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  def flag(assigns) do
    assigns
    |> set_attributes([], required: [:country, :size])
    |> extend_class("")
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <img
      {@heex_class}
      src={Routes.static_path(HamsterTravelWeb.Endpoint, "/images/flags/#{@size}/#{@country}.png")}
      alt={"Country #{@country}"}
      style={"width: #{@size}px;  height: #{@size}px"}
    />
    """
  end
end
