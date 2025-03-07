defmodule HamsterTravelWeb.Packing.ItemNew do
  @moduledoc """
  Live component responsible for create a new backpack item
  """

  use HamsterTravelWeb, :live_component

  require Logger

  alias HamsterTravel.Packing

  def update(assigns, socket) do
    changeset = Packing.new_item()

    socket =
      socket
      |> assign(assigns)
      |> assign(name: nil)
      |> assign_form(changeset)

    {:ok, socket}
  end

  def handle_event("create_item", %{"item" => %{"name" => name}}, socket)
      when is_nil(name) or name == "" do
    {:noreply, socket}
  end

  def handle_event("create_item", %{"item" => item_params}, socket) do
    case Packing.create_item(item_params, socket.assigns.list) do
      {:ok, _} ->
        changeset = Packing.new_item()

        {:noreply, socket |> assign(:name, nil) |> assign_form(changeset)}

      {:error, changeset} ->
        Logger.warning(
          "Error creating item; params were #{inspect(item_params)}, result is #{inspect(changeset)}"
        )

        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("change", %{"item" => %{"name" => name}}, socket) do
    {:noreply, assign(socket, %{name: name})}
  end

  def render(assigns) do
    ~H"""
    <div class="mt-3">
      <.form for={@form} as={:item} phx-submit="create_item" phx-change="change" phx-target={@myself}>
        <.inline>
          <.input
            id={"add-item-#{@list.id}"}
            field={@form[:name]}
            placeholder={gettext("Add backpack item")}
            value={@name}
          />
          <.icon_button size="md">
            <.icon name="hero-plus" />
          </.icon_button>
        </.inline>
      </.form>
    </div>
    """
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
