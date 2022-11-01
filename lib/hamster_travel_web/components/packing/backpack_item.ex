defmodule HamsterTravelWeb.Packing.BackpackItem do
  @moduledoc """
  Live component responsible for showing and editing a single backpack item
  """

  use HamsterTravelWeb, :live_component
  import PhxComponentHelpers

  import HamsterTravelWeb.Inline

  def update(assigns, socket) do
    assigns =
      assigns
      |> set_attributes([], required: [:item])

    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div class="mt-3">
      <.form :let={f} for={:item}>
        <%= label class: "cursor-pointer" do %>
          <.inline>
            <.checkbox form={f} field={:"item-#{@item.id}"} label={@item.name} value={@item.checked} />
            <div class="text-sm"><%= @item.name %> <%= @item.count %></div>
          </.inline>
        <% end %>
      </.form>
    </div>
    """
  end
end
