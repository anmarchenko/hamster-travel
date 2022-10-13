defmodule HamsterTravelWeb.Planning.Activity do
  @moduledoc """
  Live component responsible for showing and editing activities
  """
  use HamsterTravelWeb, :live_component
  import PhxComponentHelpers

  import HamsterTravelWeb.ExternalLink
  import HamsterTravelWeb.Inline
  import HamsterTravelWeb.Secondary

  def update(assigns, socket) do
    assigns =
      assigns
      |> set_attributes([edit: false], required: [:activity, :index])

    {:ok, assign(socket, assigns)}
  end

  def render(%{edit: true} = assigns) do
    ~H"""
    Edit is not implemented yet
    """
  end

  def render(%{edit: false} = assigns) do
    ~H"""
    <div
      class="flex flex-col gap-y-1 py-1 sm:ml-[-1.5rem] sm:pl-[1.5rem] sm:hover:bg-zinc-100 sm:dark:hover:bg-zinc-700"
      x-data="{ showButtons: false, showContent: false }"
      @mouseover="showButtons = true"
      @mouseleave="showButtons = false"
    >
      <.inline class={"2xl:text-lg #{activity_font(@activity.priority)}"}>
        <span class="cursor-pointer" @click="showContent = !showContent">
          <%= "#{@index + 1}." %>
          <%= @activity.name %>
        </span>
        <%= Formatter.format_money(@activity.price, @activity.price_currency) %>
        <.activity_button>
          <Heroicons.Outline.pencil class="h-4 w-4" />
        </.activity_button>
        <.activity_button>
          <Heroicons.Outline.trash class="h-4 w-4" />
        </.activity_button>
      </.inline>
      <div
        class="flex flex-col gap-y-1"
        x-show="showContent"
        x-transition.duration.300ms.opacity
        x-cloak
      >
        <.external_link link={@activity.link} />
        <.activity_feature label={gettext("Address")} value={@activity.address} />
        <.activity_feature label={gettext("Opening hours")} value={@activity.operation_times} />
        <div class="max-w-prose whitespace-pre-line text-justify text-sm">
          <%= @activity.comment %>
        </div>
      </div>
    </div>
    """
  end

  defp activity_font("must"), do: "font-bold"
  defp activity_font("should"), do: "font-normal"
  defp activity_font("irrelevant"), do: "italic font-light text-zinc-400 dark:text-zinc-500"

  defp activity_feature(%{value: nil} = assigns) do
    ~H"""

    """
  end

  defp activity_feature(assigns) do
    ~H"""
    <.secondary class="max-w-prose">
      <%= @label %>: <%= @value %>
    </.secondary>
    """
  end

  defp activity_button(assigns) do
    ~H"""
    <span
      class="cursor-pointer hover:text-zinc-900 hover:dark:text-zinc-100"
      x-show="showButtons"
      x-transition
    >
      <%= render_slot(@inner_block) %>
    </span>
    """
  end
end
