defmodule HamsterTravelWeb.Packing.EditBackpack do
  @moduledoc """
  Create backpack form
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Container

  alias HamsterTravel.Packing
  alias HamsterTravel.Packing.Policy

  @impl true
  def mount(%{"backpack_slug" => slug}, _session, socket) do
    user = socket.assigns.current_user

    with backpack when backpack != nil <- Packing.get_backpack_by_slug(slug, user),
         true <- Policy.authorized?(:edit, backpack, user) do
      socket =
        socket
        |> assign(active_nav: :backpacks)
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

  @impl true
  def handle_event("update_backpack", %{"backpack" => backpack_params}, socket) do
    case Packing.update_backpack(socket.assigns.backpack, backpack_params) do
      {:ok, backpack} ->
        socket =
          socket
          |> push_redirect(
            to: Routes.live_path(socket, HamsterTravelWeb.Packing.ShowBackpack, backpack.slug)
          )

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, %{changeset: changeset})}
    end
  end
end
