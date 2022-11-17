defmodule HamsterTravelWeb.Packing.AddItem do
  @moduledoc """
  Live component responsible for create a new backpack item
  """

  use HamsterTravelWeb, :live_component

  import PhxComponentHelpers

  require Logger

  alias HamsterTravel.Packing

  def update(assigns, socket) do
    assigns =
      assigns
      |> set_attributes([], required: [:list])

    socket =
      socket
      |> assign(assigns)
      |> assign(changeset: Packing.new_item())

    {:ok, socket}
  end

  def handle_event("create_item", %{"item" => %{"name" => name}}, socket)
      when is_nil(name) or name == "" do
    {:noreply, socket}
  end

  def handle_event("create_item", %{"item" => item_params}, socket) do
    case Packing.create_item(item_params, socket.assigns.list) do
      {:ok, _} ->
        {:noreply, assign(socket, %{changeset: Packing.new_item()})}

      {:error, changeset} ->
        Logger.warn(
          "Error creating item; params were #{inspect(item_params)}, result is #{inspect(changeset)}"
        )

        {:noreply, assign(socket, %{changeset: changeset})}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mt-3">
      <.form :let={f} for={:item} phx-submit="create_item" phx-target={@myself} as={:item}>
        <.text_input form={f} field={:name} placeholder={gettext("Add backpack item")} />
      </.form>
    </div>
    """
  end
end
