defmodule HamsterTravelWeb.Packing.AddItem do
  @moduledoc """
  Live component responsible for create a new backpack item
  """

  use HamsterTravelWeb, :live_component

  require Logger

  alias HamsterTravel.Packing

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(changeset: Packing.new_item())
      |> assign(name: nil)

    {:ok, socket}
  end

  def handle_event("create_item", %{"item" => %{"name" => name}}, socket)
      when is_nil(name) or name == "" do
    {:noreply, socket}
  end

  def handle_event("create_item", %{"item" => item_params}, socket) do
    case Packing.create_item(item_params, socket.assigns.list) do
      {:ok, _} ->
        {:noreply, assign(socket, %{changeset: Packing.new_item(), name: nil})}

      {:error, changeset} ->
        Logger.warn(
          "Error creating item; params were #{inspect(item_params)}, result is #{inspect(changeset)}"
        )

        {:noreply, assign(socket, %{changeset: changeset})}
    end
  end

  def handle_event("change", %{"item" => %{"name" => name}}, socket) do
    {:noreply, assign(socket, %{name: name})}
  end

  def render(assigns) do
    ~H"""
    <div class="mt-3">
      <.form
        :let={f}
        for={@changeset}
        phx-submit="create_item"
        phx-change="change"
        phx-target={@myself}
        as={:item}
      >
        <.inline>
          <.text_input
            form={f}
            id={"add-item-#{@list.id}"}
            field={:name}
            placeholder={gettext("Add backpack item")}
            value={@name}
          />
          <.icon_button link_type="button" size="xs" color="gray">
            <Heroicons.Outline.plus class={
              PetalComponents.Button.get_icon_button_spinner_size_classes("xs")
            } />
          </.icon_button>
        </.inline>
      </.form>
    </div>
    """
  end
end
