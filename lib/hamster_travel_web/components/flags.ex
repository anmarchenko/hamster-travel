defmodule HamsterTravelWeb.Flags do
  @moduledoc """
  Renders flags
  """
  use HamsterTravelWeb, :component

  def flag(assigns) do
    ~H"""
    <img src={Routes.static_path(HamsterTravelWeb.Endpoint, "/images/flags/#{@size}/#{@country}.png")} alt={"Country #{@country}"} />
    """
  end
end
