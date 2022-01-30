defmodule HamsterTravelWeb.Planning.PlanHeader do
  @moduledoc """
  This component renders plan header for the plan view
  """
  use HamsterTravelWeb, :component

  alias HamsterTravelWeb.Avatar
  alias HamsterTravelWeb.Planning.PlanComponents

  def header(assigns) do
    ~H"""
    <section class="mx-auto max-w-screen-md xl:max-w-screen-lg 2xl:max-w-screen-xl p-6 mt-4">
      <div class="flex flex-col-reverse sm:flex-row">
        <div class="flex-1">
          <h1 class="text-xl font-semibold text-black dark:text-white"><%= @plan.name %></h1>
          <div class="text-zinc-600 flex flex-row gap-x-4 mt-4 dark:text-zinc-300">
            <UIComponents.icon_text>
              <Icons.money_stack />
              <%= @plan.budget %> <%= @plan.currency_symbol %>
            </UIComponents.icon_text>
            <UIComponents.icon_text>
              <Icons.calendar />
              <%= @plan.duration %> <%= ngettext("day", "days", @plan.duration) %>
            </UIComponents.icon_text>
            <UIComponents.icon_text>
              <Icons.user />
              <%= @plan.people_count %> <%= gettext("ppl") %>
            </UIComponents.icon_text>
          </div>
          <div class="flex flex-row text-xs gap-x-4 sm:text-base mt-4 ">
            <%= live_redirect to: "/plan/#{@plan.slug}/edit", class: "underline text-indigo-500 hover:text-indigo-900 dark:text-indigo-300 dark:hover:text-indigo-100" do %>
              <%= gettext("Edit plan") %>
            <% end %>
            <%= live_redirect to: "/plan/#{@plan.slug}/copy", class: "underline text-indigo-500 hover:text-indigo-900 dark:text-indigo-300 dark:hover:text-indigo-100" do %>
              <%= gettext("Make a copy") %>
            <% end %>
            <%= live_redirect to: "/plan/#{@plan.slug}/pdf", class: "underline text-indigo-500 hover:text-indigo-900 dark:text-indigo-300 dark:hover:text-indigo-100" do %>
              <%= gettext("Export as PDF") %>
            <% end %>
          </div>
          <div class="flex flex-row gap-x-3 mt-4">
            <PlanComponents.status_badge status={@plan.status} />
            <%= for country <- @plan.countries do %>
              <Flags.flag size={24} country={country} />
            <% end %>
            <Avatar.round user={@plan.author} size={:small} />
          </div>
        </div>
        <div class="">
          <img class="max-h-52 mb-4 sm:mb-0 sm:h-36 sm:w-auto sm:max-h-full shadow-lg rounded-md" src={@plan.cover} />
        </div>
      </div>
    </section>
    """
  end
end
