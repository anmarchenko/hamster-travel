defmodule HamsterTravelWeb.Packing.CreateBackpack do
  @moduledoc """
  Create backpack form
  """
  use HamsterTravelWeb, :live_view

  alias Ecto.Changeset

  alias HamsterTravel.Packing

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(active_nav: :backpacks)
      |> assign(page_title: gettext("Create backpack"))
      |> assign(changeset: Packing.new_backpack())
      |> assign(error_message: nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("create_backpack", %{"backpack" => backpack_params}, socket) do
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

  @impl true
  def handle_event("days-changed", %{"backpack" => %{"days" => days}}, socket) do
    {days, _} = Integer.parse(days)

    if days > 1 do
      changeset = socket.assigns.changeset |> Changeset.put_change(:nights, days - 1)
      {:noreply, assign(socket, %{changeset: changeset})}
    else
      {:noreply, socket}
    end
  end
end
