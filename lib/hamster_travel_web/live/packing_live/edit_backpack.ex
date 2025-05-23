defmodule HamsterTravelWeb.Packing.EditBackpack do
  @moduledoc """
  Create backpack form
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravel.Packing
  alias HamsterTravel.Packing.Policy

  alias HamsterTravelWeb.Packing.BackpackForm

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      module={BackpackForm}
      id="edit-backpack-form"
      action={:edit}
      backpack={@backpack}
      back_url={backpack_url(@backpack.slug)}
    />
    """
  end

  @impl true
  def mount(%{"backpack_slug" => slug}, _session, socket) do
    user = socket.assigns.current_user
    backpack = Packing.fetch_backpack!(slug, user)

    if Policy.authorized?(:edit, backpack, user) do
      socket =
        socket
        |> assign(active_nav: backpacks_nav_item())
        |> assign(page_title: gettext("Edit backpack"))
        |> assign(backpack: backpack)

      {:ok, socket}
    else
      raise HamsterTravelWeb.Errors.NotAuthorized
    end
  end
end
