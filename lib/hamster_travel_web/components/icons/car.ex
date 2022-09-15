defmodule HamsterTravelWeb.Icons.Car do
  @moduledoc """
  Car icon
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  def car(assigns) do
    assigns
    |> extend_class("", prefix_replace: false)
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <svg
      width="18"
      height="18"
      stroke-width="1.5"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      {@heex_class}
    >
      <path d="M8 10L16 10" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" />
      <path d="M7 14L8 14" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" />
      <path d="M16 14L17 14" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" />
      <path
        d="M3 18V11.4105C3 11.1397 3.05502 10.8716 3.16171 10.6227L5.4805 5.21216C5.79566 4.47679 6.51874 4 7.31879 4H16.6812C17.4813 4 18.2043 4.47679 18.5195 5.21216L20.8383 10.6227C20.945 10.8716 21 11.1397 21 11.4105V18M3 18V20.4C3 20.7314 3.26863 21 3.6 21H6.4C6.73137 21 7 20.7314 7 20.4V18M3 18H7M21 18V20.4C21 20.7314 20.7314 21 20.4 21H17.6C17.2686 21 17 20.7314 17 20.4V18M21 18H17M7 18H17"
        stroke="currentColor"
        stroke-width="1.5"
      />
    </svg>
    """
  end
end
