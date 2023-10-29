defmodule HamsterTravelWeb.Packing.EditBackpack do
  @moduledoc """
  Create backpack form
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravel.Packing
  alias HamsterTravel.Packing.Policy

  alias HamsterTravelWeb.Packing.BackpackForm

  @impl true
  def mount(%{"backpack_slug" => slug}, _session, socket) do
    user = socket.assigns.current_user

    with backpack when backpack != nil <- Packing.fetch_backpack(slug, user),
         true <- Policy.authorized?(:edit, backpack, user) do
      socket =
        socket
        |> assign(active_nav: backpacks_nav_item())
        |> assign(page_title: gettext("Edit backpack"))
        |> assign(backpack: backpack)
        |> assign(changeset: Packing.change_backpack(backpack))

      {:ok, socket}
    else
      nil ->
        {:ok, socket, layout: {HamsterTravelWeb.LayoutView, "not_found.html"}}

      false ->
        {:ok, socket, layout: {HamsterTravelWeb.LayoutView, "not_found.html"}}
    end
  end

  def update_backpack(socket, backpack_params) do
    case Packing.update_backpack(socket.assigns.backpack, backpack_params) do
      {:ok, backpack} ->
        socket =
          socket
          |> push_redirect(to: ~p"/backpacks/#{backpack.slug}")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, %{changeset: changeset})}
    end
  end
end
