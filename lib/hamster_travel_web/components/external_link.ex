defmodule HamsterTravelWeb.ExternalLink do
  @moduledoc """
  Parses and renders an external link
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  import HamsterTravelWeb.Link

  def external_link(assigns) do
    assigns
    |> set_attributes(link: nil)
    |> render()
  end

  defp render(%{link: nil} = assigns) do
    ~H"""

    """
  end

  defp render(assigns) do
    uri = URI.parse(assigns[:link])

    ~H"""
    <.a to={@link} link_type="a" label={uri.host} />
    """
  end
end
