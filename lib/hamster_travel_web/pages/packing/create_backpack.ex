defmodule HamsterTravelWeb.Packing.CreateBackpack do
  @moduledoc """
  Create backpack form
  """
  use HamsterTravelWeb, :live_view

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
  def handle_event(
        "form_changed",
        %{"_target" => ["backpack", "days"], "backpack" => %{"days" => days} = backpack_params},
        socket
      )
      when days != nil and days != "" do
    {days, _} = Integer.parse(days)

    if days > 1 do
      backpack_params
      |> Map.put("nights", days - 1)
      |> replace_changeset_from_params(socket)
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "form_changed",
        %{
          "_target" => ["backpack", "nights"],
          "backpack" => %{"nights" => nights} = backpack_params
        },
        socket
      )
      when nights != nil and nights != "" do
    {nights, _} = Integer.parse(nights)

    if nights > 0 do
      backpack_params
      |> Map.put("days", nights + 1)
      |> replace_changeset_from_params(socket)
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "form_changed",
        _,
        socket
      ) do
    {:noreply, socket}
  end

  defp replace_changeset_from_params(params, socket) do
    {:noreply, assign(socket, %{changeset: Packing.backpack_changeset(params)})}
  end
end
