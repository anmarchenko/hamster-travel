defmodule HamsterTravelWeb.ExternalLinks do
  @moduledoc """
  Renders a list of external links with line breaks between them
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  import HamsterTravelWeb.ExternalLink

  def external_links(assigns) do
    assigns
    |> set_attributes([], required: [:links])
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <%= for link <- @links do %>
      <.external_link link={link} />
    <% end %>
    """
  end
end
