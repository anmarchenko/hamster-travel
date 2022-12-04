defmodule HamsterTravelWeb.Packing.ShowBackpack do
  @moduledoc """
  Backpack page
  """
  use HamsterTravelWeb, :live_view

  require Logger

  import HamsterTravel.Collections

  import HamsterTravelWeb.Container
  import HamsterTravelWeb.Header
  import HamsterTravelWeb.Inline
  import HamsterTravelWeb.Link

  alias HamsterTravel.Packing
  alias HamsterTravel.Packing.Backpack
  alias HamsterTravel.Packing.List
  alias HamsterTravel.Packing.Policy

  alias HamsterTravelWeb.Packing.AddList
  alias HamsterTravelWeb.Packing.BackpackList

  @impl true
  def mount(%{"backpack_slug" => slug}, _session, socket) do
    case Packing.get_backpack_by_slug(slug, socket.assigns.current_user) do
      nil ->
        {:ok, socket, layout: {HamsterTravelWeb.LayoutView, "not_found.html"}}

      backpack ->
        Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "backpacks:#{backpack.id}")

        socket =
          socket
          |> assign(active_nav: :backpacks)
          |> assign(page_title: backpack.name)
          |> assign(backpack: backpack)

        {:ok, socket}
    end
  end

  @impl true
  def handle_info({[:item, :updated], %{value: updated_item}}, socket) do
    backpack = socket.assigns.backpack

    {:noreply,
     assign(socket, :backpack, %Backpack{
       backpack
       | lists:
           replace(
             backpack.lists,
             fn list -> list.id == updated_item.backpack_list_id end,
             fn list ->
               %List{
                 list
                 | items:
                     replace(
                       list.items,
                       fn item -> item.id == updated_item.id end,
                       fn _ -> updated_item end
                     )
               }
             end
           )
     })}
  end

  @impl true
  def handle_info({[:item, :created], %{value: created_item}}, socket) do
    # TODO: refetch from database after implementing ordering
    backpack = socket.assigns.backpack

    {:noreply,
     assign(socket, :backpack, %Backpack{
       backpack
       | lists:
           replace(
             backpack.lists,
             fn list -> list.id == created_item.backpack_list_id end,
             fn list ->
               %List{
                 list
                 | items: (list.items || []) ++ [created_item]
               }
             end
           )
     })}
  end

  def handle_info({[:item, :deleted], %{value: deleted_item}}, socket) do
    backpack = socket.assigns.backpack

    {:noreply,
     assign(socket, :backpack, %Backpack{
       backpack
       | lists:
           replace(
             backpack.lists,
             fn list -> list.id == deleted_item.backpack_list_id end,
             fn list ->
               %List{
                 list
                 | items:
                     replace(
                       list.items,
                       fn item -> item.id == deleted_item.id end,
                       fn _ -> nil end
                     )
               }
             end
           )
     })}
  end

  @impl true
  def handle_info({[:list, :updated], %{value: updated_list}}, socket) do
    backpack = socket.assigns.backpack

    {:noreply,
     assign(socket, :backpack, %Backpack{
       backpack
       | lists:
           replace(
             backpack.lists,
             fn list -> list.id == updated_list.id end,
             fn list ->
               %List{
                 updated_list
                 | items: list.items
               }
             end
           )
     })}
  end

  def handle_info({[:list, :deleted], %{value: deleted_list}}, socket) do
    backpack = socket.assigns.backpack

    {:noreply,
     assign(socket, :backpack, %Backpack{
       backpack
       | lists:
           replace(
             backpack.lists,
             fn list -> list.id == deleted_list.id end,
             fn _ -> nil end
           )
     })}
  end

  @impl true
  def handle_event("delete_backpack", _params, socket) do
    %{backpack: backpack, current_user: user} = socket.assigns

    if Policy.authorized?(:delete, backpack, user) do
      Packing.delete_backpack(backpack)

      socket =
        socket
        |> push_redirect(to: Routes.live_path(socket, HamsterTravelWeb.Packing.IndexBackpacks))

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end
end
