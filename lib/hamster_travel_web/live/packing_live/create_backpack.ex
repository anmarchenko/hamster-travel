defmodule HamsterTravelWeb.Packing.CreateBackpack do
  @moduledoc """
  Create backpack form
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravel.Packing
  alias HamsterTravel.Packing.Policy

  alias HamsterTravelWeb.Packing.BackpackForm

  @impl true
  def mount(params, _session, socket) do
    socket =
      with %{"copy" => backpack_id} <- params,
           backpack when backpack != nil <- Packing.get_backpack(backpack_id),
           true <- Policy.authorized?(:copy, backpack, socket.assigns.current_user) do
        socket
        |> assign(changeset: Packing.new_backpack(backpack))
        |> assign(copy_from: backpack)
        |> assign(back_url: backpack_url(backpack.slug))
      else
        _ ->
          socket
          |> assign(changeset: Packing.new_backpack())
          |> assign(copy_from: nil)
          |> assign(back_url: backpacks_url())
      end

    socket =
      socket
      |> assign(active_nav: backpacks_nav_item())
      |> assign(page_title: gettext("Create backpack"))

    {:ok, socket}
  end

  def create_backpack(%{assigns: %{copy_from: backpack}} = socket, backpack_params)
      when backpack != nil do
    backpack_params
    |> Packing.create_backpack(socket.assigns.current_user, backpack)
    |> result(socket)
  end

  def create_backpack(socket, backpack_params) do
    backpack_params
    |> Packing.create_backpack(socket.assigns.current_user)
    |> result(socket)
  end

  def result({:ok, backpack}, socket) do
    socket =
      socket
      |> push_redirect(to: ~p"/backpacks/#{backpack.slug}")

    {:noreply, socket}
  end

  def result({:error, changeset}, socket) do
    {:noreply, assign(socket, %{changeset: changeset})}
  end
end
