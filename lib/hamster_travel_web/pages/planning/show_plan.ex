defmodule HamsterTravelWeb.Planning.ShowPlan do
  @moduledoc """
  Plan page
  """
  use HamsterTravelWeb, :live_view

  alias HamsterTravelWeb.Planning.PlanComponents
  alias HamsterTravelWeb.Planning.Tabs.{ActivitiesTab, TransfersTab}

  @tabs ["activities", "transfers", "catering", "documents", "report"]

  @impl true
  def mount(%{"plan_slug" => slug} = params, _session, socket) do
    case HamsterTravel.find_plan_by_slug(slug) do
      {:ok, plan} ->
        socket =
          socket
          |> assign(mobile_menu: :plan_tabs)
          |> assign(active_nav: active_nav(plan))
          |> assign(active_tab: fetch_tab(params))
          |> assign(page_title: plan.name)
          |> assign(plan: plan)

        {:ok, socket}

      {:error, :not_found} ->
        {:ok, socket, layout: {HamsterTravelWeb.LayoutView, "not_found.html"}}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(active_tab: fetch_tab(params))

    {:noreply, socket}
  end

  def render_tab(%{active_tab: "transfers"} = assigns) do
    ~H"""
    <.live_component module={TransfersTab} id={"plan-#{@plan.id}-transfers"} plan={@plan} />
    """
  end

  def render_tab(%{active_tab: "activities"} = assigns) do
    ~H"""
    <.live_component module={ActivitiesTab} id={"plan-#{@plan.id}-activities"} plan={@plan} />
    """
  end

  defp active_nav(%{status: "draft"}), do: :drafts
  defp active_nav(_), do: :plans

  defp fetch_tab(%{"tab" => tab})
       when tab in @tabs,
       do: tab

  defp fetch_tab(_), do: "transfers"
end
