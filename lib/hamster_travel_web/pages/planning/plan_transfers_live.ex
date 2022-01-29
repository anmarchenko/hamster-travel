defmodule HamsterTravelWeb.Planning.PlanTransfersLive do
  @moduledoc """
  Plan page with transfers tab open
  """
  use HamsterTravelWeb, :live_view

  @impl true
  def mount(%{"plan_slug" => slug}, _session, socket) do
    case HamsterTravel.find_plan_by_slug(slug) do
      {:ok, plan} ->
        socket =
          socket
          |> assign(active_nav: active_nav(plan))
          |> assign(active_tab: :transfers)
          |> assign(page_title: plan.name)
          |> assign(plan: plan)

        {:ok, socket}

      {:error, :not_found} ->
        {:ok, socket, layout: {HamsterTravelWeb.LayoutView, "not_found.html"}}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp active_nav(%{status: "draft"}), do: :drafts
  defp active_nav(_), do: :plans
end
