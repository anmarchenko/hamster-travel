defmodule HamsterTravelWeb.Packing.CreateBackpack do
  @moduledoc """
  Create backpack form
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravel.Packing
  alias HamsterTravel.Packing.Policy

  alias HamsterTravelWeb.Packing.Backpacks.FormComponent

  @impl true
  def mount(params, _session, socket) do
    socket =
      with %{"copy" => backpack_id} <- params,
           backpack when backpack != nil <- Packing.get_backpack(backpack_id),
           true <- Policy.authorized?(:copy, backpack, socket.assigns.current_user) do
        socket
        |> assign(copy_from: backpack)
        |> assign(back_url: backpack_url(backpack.slug))
      else
        _ ->
          socket
          |> assign(copy_from: nil)
          |> assign(back_url: backpacks_url())
      end

    socket =
      socket
      |> assign(active_nav: backpacks_nav_item())
      |> assign(page_title: gettext("Create backpack"))

    {:ok, socket}
  end
end
