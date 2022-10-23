defmodule HamsterTravelWeb.Packing.UpdateBackpack do
  @moduledoc """
  Create backpack form
  """
  use HamsterTravelWeb, :live_view

  import HamsterTravelWeb.Container

  alias HamsterTravel.Packing

  @impl true
  def mount(%{"backpack_slug" => slug}, _session, socket) do
    case Packing.get_backpack_by_slug(slug, socket.assigns.current_user) do
      nil ->
        {:ok, socket, layout: {HamsterTravelWeb.LayoutView, "not_found.html"}}

      backpack ->
        socket =
          socket
          |> assign(active_nav: :backpacks)
          |> assign(page_title: gettext("Update backpack"))
          |> assign(changeset: Packing.change_backpack(backpack))

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("update_backpack", %{"backpack" => backpack_params}, socket) do
    case Packing.update_backpack(backpack_params, socket.assigns.current_user) do
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
