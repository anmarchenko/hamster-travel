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
      else
        _ ->
          assign(socket, changeset: Packing.new_backpack())
      end

    socket =
      socket
      |> assign(active_nav: :backpacks)
      |> assign(page_title: gettext("Create backpack"))

    {:ok, socket}
  end

  def create_backpack(socket, backpack_params) do
    backpack_params = Map.put(backpack_params, "template", "hamsters")

    case Packing.create_backpack(backpack_params, socket.assigns.current_user) do
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
