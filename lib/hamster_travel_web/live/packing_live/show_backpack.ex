defmodule HamsterTravelWeb.Packing.ShowBackpack do
  @moduledoc """
  Backpack page
  """
  use HamsterTravelWeb, :live_view

  require Logger

  import HamsterTravel.Collections

  alias HamsterTravel.Packing
  alias HamsterTravel.Packing.Backpack
  alias HamsterTravel.Packing.List
  alias HamsterTravel.Packing.Policy

  alias HamsterTravelWeb.Packing.List, as: ListComponent
  alias HamsterTravelWeb.Packing.ListNew

  @impl true
  def render(assigns) do
    ~H"""
    <.container full class="!mt-* mt-4">
      <div class="flex flex-col gap-y-4">
        <.header>
          {@backpack.name}
        </.header>
        <.inline class="gap-4">
          <.icon name="hero-calendar" class="h-4 w-4" />
          {@backpack.days} {ngettext("day", "days", @backpack.days)} / {@backpack.nights} {ngettext(
            "night",
            "nights",
            @backpack.nights
          )}
        </.inline>
        <.inline class="text-xs gap-4 sm:text-base">
          <.button
            :if={Policy.authorized?(:edit, @backpack, @current_user)}
            link_type="live_redirect"
            to={backpack_url(@backpack.slug, :edit)}
            color="secondary"
          >
            <.icon_text icon="hero-pencil" label={gettext("Edit")} />
          </.button>
          <.button
            :if={Policy.authorized?(:copy, @backpack, @current_user)}
            link_type="live_redirect"
            to={backpack_url(@backpack.id, :copy)}
            color="secondary"
          >
            <.icon_text icon="hero-document-duplicate" label={gettext("Make a copy")} />
          </.button>
          <.button
            :if={Policy.authorized?(:delete, @backpack, @current_user)}
            phx-click="delete_backpack"
            data-confirm={gettext("Are you sure you want to delete backpack?")}
            color="danger"
          >
            <.icon_text icon="hero-trash" label={gettext("Delete")} />
          </.button>
        </.inline>
      </div>
    </.container>

    <.container full class="!mt-* mt-0">
      <.live_component module={ListNew} id={"add_item-#{@backpack.id}"} backpack={@backpack} />
      <div
        class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"
        phx-hook="PackingDragDrop"
        id="packing-lists-container"
      >
        <.live_component
          :for={items_list <- @backpack.lists}
          module={ListComponent}
          id={"packing-list-#{items_list.id}"}
          list={items_list}
        />
      </div>
    </.container>
    """
  end

  @impl true
  def mount(%{"backpack_slug" => slug}, _session, socket) do
    backpack = Packing.fetch_backpack!(slug, socket.assigns.current_user)

    Phoenix.PubSub.subscribe(HamsterTravel.PubSub, "backpacks:#{backpack.id}")

    socket =
      socket
      |> assign(active_nav: :backpacks)
      |> assign(page_title: backpack.name)
      |> assign(backpack: backpack)

    {:ok, socket}
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
    # refetch from database after implementing ordering
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
  def handle_info({[:list, :created], %{value: created_list}}, socket) do
    # refetch from database after implementing ordering
    backpack = socket.assigns.backpack

    {:noreply,
     assign(socket, :backpack, %Backpack{
       backpack
       | lists: backpack.lists ++ [%List{created_list | items: []}]
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
  def handle_info({[:item, :moved], %{value: _moved_item}}, socket) do
    # Refresh the entire backpack to get the correct ordering
    backpack = Packing.get_backpack!(socket.assigns.backpack.id)
    {:noreply, assign(socket, :backpack, backpack)}
  end

  @impl true
  def handle_event(
        "move_item_to_list",
        %{"item_id" => item_id, "new_list_id" => new_list_id, "position" => position},
        socket
      ) do
    item = find_item_in_backpack(socket.assigns.backpack, item_id)

    if item do
      case Packing.move_item_to_list(item, new_list_id, position) do
        {:ok, _item} ->
          # PubSub will handle the UI update
          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to move item"))}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("reorder_item", %{"item_id" => item_id, "position" => position}, socket) do
    item = find_item_in_backpack(socket.assigns.backpack, item_id)

    if item do
      case Packing.reorder_item(item, position) do
        {:ok, _item} ->
          # PubSub will handle the UI update
          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to reorder item"))}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_backpack", _params, socket) do
    %{backpack: backpack, current_user: user} = socket.assigns

    if Policy.authorized?(:delete, backpack, user) do
      Packing.delete_backpack(backpack)

      socket =
        socket
        |> push_navigate(to: ~p"/backpacks")

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp find_item_in_backpack(backpack, item_id) do
    backpack.lists
    |> Enum.flat_map(& &1.items)
    |> Enum.find(&(&1.id == item_id))
  end
end
