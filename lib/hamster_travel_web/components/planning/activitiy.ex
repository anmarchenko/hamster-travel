defmodule HamsterTravelWeb.Planning.Activity do
  @moduledoc """
  Live component responsible for showing and editing activities
  """
  use HamsterTravelWeb, :live_component

  import HamsterTravelWeb.Inline

  alias Phoenix.LiveView.JS

  def update(%{activity: activity, index: index}, socket) do
    socket =
      socket
      |> assign(activity: activity)
      |> assign(index: index)
      |> assign(edit: false)

    {:ok, socket}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    Edit is not implemented yet
    """
  end

  def render(%{edit: false, activity: activity, index: index} = assigns) do
    ~H"""
    <div
      class="flex flex-col gap-y-1 py-1 sm:ml-[-1.5rem] sm:pl-[1.5rem] sm:hover:bg-zinc-100 sm:dark:hover:bg-zinc-700"
      x-data="{ showButtons: false }"
      @mouseover="showButtons = true"
      @mouseleave="showButtons = false"
    >
      <.inline class={"2xl:text-lg #{activity_font(activity.priority)}"}>
        <span
          class="cursor-pointer"
          phx-click={
            JS.toggle(
              to: "#activity-content-#{activity.id}",
              display: "flex",
              in: {"ease-out duration-300", "opacity-0", "opacity-100"},
              out: {"ease-out duration-300", "opacity-100", "opacity-0"}
            )
          }
        >
          <%= "#{index + 1}." %>
          <%= activity.name %>
        </span>
        <%= Formatter.format_money(activity.price, activity.price_currency) %>
        <.activity_button>
          <Heroicons.Outline.pencil class="h-4 w-4" />
        </.activity_button>
        <.activity_button>
          <Heroicons.Outline.trash class="h-4 w-4" />
        </.activity_button>
      </.inline>
      <div id={"activity-content-#{activity.id}"} class="hidden flex flex-col gap-y-1">
        <UI.external_link link={activity.link} />
        <.activity_feature label={gettext("Address")} value={activity.address} />
        <.activity_feature label={gettext("Opening hours")} value={activity.operation_times} />
        <div class="max-w-prose whitespace-pre-line text-justify text-sm">
          <%= activity.comment %>
        </div>
      </div>
    </div>
    """
  end

  def activity_font("must"), do: "font-bold"
  def activity_font("should"), do: "font-normal"
  def activity_font("irrelevant"), do: "italic font-light text-zinc-400 dark:text-zinc-500"

  def activity_feature(%{value: nil} = assigns) do
    ~H"""

    """
  end

  def activity_feature(%{value: value, label: label} = assigns) do
    ~H"""
    <UI.secondary_text class="max-w-prose">
      <%= label %>: <%= value %>
    </UI.secondary_text>
    """
  end

  def activity_button(assigns) do
    ~H"""
    <span
      class="cursor-pointer hover:text-zinc-900 hover:dark:text-zinc-100"
      x-bind:class="!showButtons ? 'sm:hidden' : ''"
      x-cloak
    >
      <%= render_slot(@inner_block) %>
    </span>
    """
  end
end
