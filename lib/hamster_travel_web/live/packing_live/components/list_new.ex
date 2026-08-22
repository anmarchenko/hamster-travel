defmodule HamsterTravelWeb.Packing.ListNew do
  @moduledoc """
  Live component responsible for creating a new backpack list
  """

  require Logger

  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Packing

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(edit: false)

    {:ok, socket}
  end

  def handle_event("edit", _, socket) do
    changeset = Packing.new_list()

    socket =
      socket
      |> assign(:edit, true)
      |> assign_form(changeset)

    {:noreply, socket}
  end

  def handle_event("cancel", _, socket) do
    socket =
      socket
      |> assign(:edit, false)

    {:noreply, socket}
  end

  def handle_event("create", %{"list" => list_params}, socket) do
    case Packing.create_list(list_params, socket.assigns.backpack) do
      {:ok, _} ->
        {:noreply, assign(socket, %{edit: false})}

      {:error, changeset} ->
        Logger.warning(
          "Error creating list; params were #{inspect(list_params)}, result is #{inspect(changeset)}"
        )

        {:noreply, assign_form(socket, changeset)}
    end
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    <div class="mb-3">
      <.inline class="gap-1">
        <.form for={@form} phx-submit="create" phx-target={@myself} as={:list}>
          <.inline class="gap-1">
            <span class="inline-flex" x-init="$nextTick(() => $el.querySelector('input')?.focus())">
              <.input
                id={"add-list-#{@backpack.id}"}
                field={@form[:name]}
                placeholder={gettext("List name")}
                class="!h-8 !px-2 !py-1 !text-xs"
              />
            </span>
            <.icon_button size="xs" class="!h-8 !w-8 !p-1.5">
              <.icon name="hero-check" class="h-4 w-4" />
            </.icon_button>
          </.inline>
        </.form>
        <.icon_button
          size="xs"
          class="!h-8 !w-8 !p-1.5"
          phx-click="cancel"
          phx-target={@myself}
        >
          <.icon name="hero-x-mark" class="h-4 w-4" />
        </.icon_button>
      </.inline>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="mb-3">
      <.button color="primary" size="xs" phx-click="edit" phx-target={@myself}>
        <.icon name="hero-plus-solid" class="mr-1.5 h-4 w-4" />
        {gettext("Add list")}
      </.button>
    </div>
    """
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
