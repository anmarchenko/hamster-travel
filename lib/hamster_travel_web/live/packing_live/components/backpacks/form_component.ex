defmodule HamsterTravelWeb.Packing.Backpacks.FormComponent do
  @moduledoc """
  Live backpack create/edit form
  """
  use HamsterTravelWeb, :live_component

  alias HamsterTravel.Packing

  @impl true
  def update(assigns, socket) do
    changeset =
      case assigns.action do
        :new ->
          if assigns.copy_from != nil do
            Packing.new_backpack(assigns.copy_from)
          else
            Packing.new_backpack()
          end

        :edit ->
          Packing.change_backpack(assigns.backpack)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form_container>
        <.form
          for={@form}
          as={:backpack}
          phx-submit="form_submit"
          phx-change="form_changed"
          phx-target={@myself}
        >
          <div class="grid grid-cols-6 gap-x-6">
            <div class="col-span-6">
              <.field
                type="text"
                field={@form[:name]}
                label={gettext("Backpack name")}
                required={true}
                autofocus={true}
              />
            </div>
            <div class="col-span-3">
              <.field
                type="number"
                field={@form[:days]}
                label={gettext("Backpack days")}
                required={true}
              />
            </div>

            <div class="col-span-3">
              <.field
                type="number"
                field={@form[:nights]}
                label={gettext("Backpack nights")}
                required={true}
              />
            </div>
            <div class="col-span-6">
              <.field
                :if={@action == :new && @copy_from == nil}
                type="select"
                field={@form[:template]}
                label={gettext("Backpack template")}
                options={[:default, :sea, :mountains]}
                required={true}
              />
            </div>
          </div>

          <div class="flex justify-between">
            <.button link_type="live_redirect" to={@back_url} color="white">
              <%= gettext("Cancel") %>
            </.button>
            <.button color="primary">
              <%= gettext("Save") %>
            </.button>
          </div>
        </.form>
      </.form_container>
    </div>
    """
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
      |> replace_form_from_params(socket)
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
      |> replace_form_from_params(socket)
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

  @impl true
  def handle_event("form_submit", %{"backpack" => backpack_params}, socket) do
    on_submit(socket, socket.assigns.action, backpack_params)
  end

  def on_submit(%{assigns: %{copy_from: backpack}} = socket, :new, backpack_params)
      when backpack != nil do
    backpack_params
    |> Packing.create_backpack(socket.assigns.current_user, backpack)
    |> result(socket)
  end

  def on_submit(socket, :new, backpack_params) do
    backpack_params
    |> Packing.create_backpack(socket.assigns.current_user)
    |> result(socket)
  end

  def on_submit(socket, :edit, backpack_params) do
    socket.assigns.backpack
    |> Packing.update_backpack(backpack_params)
    |> result(socket)
  end

  def result({:ok, backpack}, socket) do
    socket =
      socket
      |> push_redirect(to: ~p"/backpacks/#{backpack.slug}")

    {:noreply, socket}
  end

  def result({:error, changeset}, socket) do
    {
      :noreply,
      socket
      |> assign_form(changeset)
    }
  end

  defp replace_form_from_params(params, socket) do
    changeset = Packing.backpack_changeset(params)
    {:noreply, assign_form(socket, changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
