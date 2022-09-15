defmodule HamsterTravelWeb.Icons.HomeSimple do
  @moduledoc """
  Simple home icon
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  def home_simple(assigns) do
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
      <path
        d="M9 21H7C4.79086 21 3 19.2091 3 17V10.7076C3 9.30887 3.73061 8.01175 4.92679 7.28679L9.92679 4.25649C11.2011 3.48421 12.7989 3.48421 14.0732 4.25649L19.0732 7.28679C20.2694 8.01175 21 9.30887 21 10.7076V17C21 19.2091 19.2091 21 17 21H15M9 21V17C9 15.3431 10.3431 14 12 14V14C13.6569 14 15 15.3431 15 17V21M9 21H15"
        stroke="currentColor"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </svg>
    """
  end
end
